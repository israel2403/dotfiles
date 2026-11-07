local M = {}
local api = vim.api
local state = { log = {}, suites = {}, collapsed = {}, rows = {} }
local icons = { passed = '✓', failed = '✗', skipped = '○', running = '◷' }
local ns = api.nvim_create_namespace('java-test-results')
local helper = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h') .. '/reports.py'

local function focus_source()
  if state.source_win and api.nvim_win_is_valid(state.source_win) then
    api.nvim_set_current_win(state.source_win)
  elseif state.source_buf and api.nvim_buf_is_valid(state.source_buf) then
    for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
      if api.nvim_win_get_buf(win) == state.source_buf then
        api.nvim_set_current_win(win)
        return
      end
    end
    vim.cmd('aboveleft split')
    api.nvim_win_set_buf(0, state.source_buf)
    state.source_win = api.nvim_get_current_win()
  end
end

function M.hide()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end
  state.win = nil
  focus_source()
end

local function render()
  if not state.buf or not api.nvim_buf_is_valid(state.buf) then return end
  local lines = { '  ' .. (state.running and '◷ Running: ' or (state.code == 0 and '✓ Passed: ' or '✗ Failed: ')) .. (state.label or ''),
    '  <Enter> expand/details   o logs/results   r rerun   s stop   q / Ctrl-/ hide', '' }
  state.rows = {}
  if state.logs then
    vim.list_extend(lines, state.log)
  else
    local counts = { passed = 0, failed = 0, skipped = 0 }
    for index, suite in ipairs(state.suites) do
      local status = 'passed'
      for _, case in ipairs(suite.cases) do
        counts[case.status] = counts[case.status] + 1
        if case.status == 'failed' then status = 'failed' end
      end
      lines[#lines + 1] = '  ' .. (state.collapsed[index] and '▸ ' or '▾ ') .. icons[status] .. ' ' .. suite.name
      state.rows[#lines] = { suite = index }
      if not state.collapsed[index] then
        for _, case in ipairs(suite.cases) do
          lines[#lines + 1] = '      ' .. icons[case.status] .. ' ' .. case.name .. (case.time ~= '' and '  (' .. case.time .. 's)' or '')
          state.rows[#lines] = { case = case }
        end
      end
    end
    if #state.suites > 0 then
      lines[3] = ('  %d passed   %d failed   %d skipped'):format(counts.passed, counts.failed, counts.skipped)
    else
      lines[#lines + 1] = state.running and '  Waiting for test reports… (o: live build log)' or '  No test reports produced. Press o for the build log.'
    end
  end
  vim.bo[state.buf].modifiable = true
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for i, line in ipairs(lines) do
    local hl = line:find('✗', 1, true) and 'DiagnosticError' or line:find('✓', 1, true) and 'DiagnosticOk'
      or line:find('○', 1, true) and 'DiagnosticWarn'
    if hl then api.nvim_buf_add_highlight(state.buf, ns, hl, i - 1, 0, -1) end
  end
end

function M.toggle()
  if state.win and api.nvim_win_is_valid(state.win) then M.hide(); return end
  if not state.buf or not api.nvim_buf_is_valid(state.buf) then
    state.buf = api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = 'hide'
    vim.bo[state.buf].filetype = 'java-test-results'
    local function map(key, fn) vim.keymap.set('n', key, fn, { buffer = state.buf, silent = true }) end
    map('q', M.hide)
    map('<Esc>', M.hide)
    map('<C-/>', M.hide)
    map('<C-_>', M.hide)
    map('o', function() state.logs = not state.logs; render() end)
    map('r', function() if state.spec then M.run(state.spec) end end)
    map('s', function() if state.job then vim.fn.jobstop(state.job) end end)
    map('<CR>', function()
      local row = state.rows[api.nvim_win_get_cursor(0)[1]]
      if not row then return end
      if row.suite then
        state.collapsed[row.suite] = not state.collapsed[row.suite]; render()
      elseif row.case then
        local detail = row.case.detail ~= '' and row.case.detail or 'No failure details.'
        vim.lsp.util.open_floating_preview(vim.split(detail, '\n', { plain = true }), 'text', { border = 'rounded', focus = true })
      end
    end)
  end
  vim.cmd('botright 15split')
  state.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(state.win, state.buf)
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = 'no'
  vim.wo[state.win].winfixheight = true
  local panels = require('task-panels')
  panels.register('java-tests', {
    label = 'Test Results',
    window = function() return state.win end,
    hide = M.hide,
    show = M.toggle,
  })
  panels.activate('java-tests')
  panels.refresh()
  render()
end

local function stamp(path)
  local s = vim.uv.fs_stat(path)
  return s and (s.mtime.sec .. ':' .. s.mtime.nsec .. ':' .. s.size)
end

function M.run(spec)
  if state.running then vim.notify('A test run is already active', vim.log.levels.WARN); return end
  state.spec, state.label = spec, spec.label
  state.log, state.suites, state.collapsed, state.logs = { '' }, {}, {}, false
  state.source_win, state.source_buf = spec.win, spec.buf
  state.running, state.code = true, nil
  local before = {}
  local pattern = spec.root .. '/target/' .. (spec.integration and 'failsafe' or 'surefire') .. '-reports/TEST-*.xml'
  for _, path in ipairs(vim.fn.glob(pattern, false, true)) do before[path] = stamp(path) end
  if not state.win or not api.nvim_win_is_valid(state.win) then M.toggle() else render() end
  require('task-panels').activate('java-tests')
  focus_source()
  local function output(_, data)
    if not data then return end
    -- jobstart delivers partial lines at the end of each chunk.
    state.log[#state.log] = (state.log[#state.log] or '') .. data[1]
    for i = 2, #data do state.log[#state.log + 1] = data[i] end
    if state.logs then render() end
  end
  state.job = vim.fn.jobstart(spec.command, {
    cwd = spec.root, stdout_buffered = false, stderr_buffered = false,
    on_stdout = output, on_stderr = output,
    on_exit = function(_, code)
      state.job = nil
      local files = {}
      for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
        if stamp(path) ~= before[path] then files[#files + 1] = path end
      end
      vim.system({ 'python3', helper }, { stdin = vim.json.encode({ files = files }), text = true }, function(result)
        vim.schedule(function()
          state.running, state.code = false, code
          local ok, suites = pcall(vim.json.decode, result.stdout or '')
          state.suites = ok and suites or {}
          if not ok then state.log[#state.log + 1] = 'Report reader: ' .. (result.stderr or 'invalid JSON') end
          render()
          vim.notify(spec.label .. (code == 0 and ' passed' or ' failed; see test results'), code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
        end)
      end)
    end,
  })
  if state.job <= 0 then
    state.running, state.code = false, -1
    state.log = { 'Could not start Maven: ' .. spec.command[1] }
    render()
  end
end

local function launch(file, root, extra, source)
  local relative = vim.fs.relpath(root, file)
  local class = relative and relative:match('^src/test/java/(.+)%.java$')
  if not class then vim.notify('Choose a Java class under src/test/java', vim.log.levels.WARN); return end
  local name = vim.fn.fnamemodify(file, ':t:r')
  local integration = name:match('IT$') or name:match('^IT') or name:match('ITCase$')
  local wrapper = root .. '/mvnw'
  local command = { vim.fn.executable(wrapper) == 1 and wrapper or 'mvn', '-B', '-ntp', '-Dstyle.color=never' }
  vim.list_extend(command, extra or {})
  command[#command + 1] = (integration and '-Dit.test=' or '-Dtest=') .. class:gsub('/', '.')
  command[#command + 1] = integration and '-Dfailsafe.failIfNoSpecifiedTests=true' or '-Dsurefire.failIfNoSpecifiedTests=true'
  vim.list_extend(command, integration and { 'test-compile', 'failsafe:integration-test', 'failsafe:verify' } or { 'test' })
  M.run({ root = root, command = command, integration = integration, label = name,
    win = source.win, buf = source.buf })
end

function M.file()
  if state.running then vim.notify('A test run is already active', vim.log.levels.WARN); return end
  local file = api.nvim_buf_get_name(0)
  local root = file ~= '' and vim.fs.root(file, 'pom.xml') or nil
  if not root then vim.notify('Open a Maven test or feature file first', vim.log.levels.WARN); return end
  local source = { win = api.nvim_get_current_win(), buf = api.nvim_get_current_buf() }
  if vim.bo.modified then vim.cmd.write() end
  if file:match('%.feature$') then
    local resource = vim.fs.relpath(root .. '/src/test/resources', file)
    if not resource or resource:match('^%.%.') then
      vim.notify('Feature must be under src/test/resources', vim.log.levels.WARN); return
    end
    local matches = {}
    for _, candidate in ipairs(vim.fn.glob(root .. '/src/test/java/**/*.java', false, true)) do
      local text = table.concat(vim.fn.readfile(candidate), '\n')
      if text:find('cucumber', 1, true) and (text:find('@Suite', 1, true) or text:find('@RunWith', 1, true)) then
        local selected = false
        for path in text:gmatch('@SelectClasspathResource%s*%(%s*"([^"]+)"') do
          path = path:gsub('/$', '')
          if resource == path or resource:sub(1, #path + 1) == path .. '/' then selected = true end
        end
        if selected then matches[#matches + 1] = candidate end
      end
    end
    if #matches == 0 then
      vim.notify('No Cucumber @Suite with a matching @SelectClasspathResource found', vim.log.levels.WARN); return
    end
    local function run(candidate)
      if candidate then
        launch(candidate, root, nil, source)
      end
    end
    if #matches == 1 then run(matches[1]) else
      vim.ui.select(matches, { prompt = 'Cucumber suite', format_item = function(path) return vim.fs.relpath(root, path) end }, run)
    end
  else
    launch(file, root, nil, source)
  end
end

M._state = state
return M
