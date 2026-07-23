-- Kotlin development support layered on LazyVim's Kotlin extra.
--
-- The extra provides kotlin-language-server, Kotlin Tree-sitter highlighting,
-- ktlint diagnostics/formatting, and nvim-dap configuration. This module makes
-- every external tool self-installing and adds Gradle project/run workflows.

local function project_root()
  local markers = {
    "settings.gradle.kts",
    "settings.gradle",
    "build.gradle.kts",
    "build.gradle",
    "pom.xml",
  }
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = vim.uv.cwd()
  end
  local marker = vim.fs.find(markers, { path = start, upward = true })[1]
  return marker and vim.fs.dirname(marker) or nil
end

local function gradle_build_root()
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = vim.uv.cwd()
  end
  local settings = vim.fs.find({ "settings.gradle.kts", "settings.gradle" }, { path = start, upward = true })[1]
  return settings and vim.fs.dirname(settings) or nil
end

local function gradle_command(root)
  local wrapper = root .. "/gradlew"
  if vim.fn.executable(wrapper) == 1 then
    return vim.fn.shellescape(wrapper)
  end
  if vim.fn.executable("gradle") == 1 then
    return "gradle"
  end
  return nil
end

local last_terminal

local function run_terminal(command, root, title)
  if last_terminal then
    pcall(function()
      last_terminal:close()
    end)
  end
  last_terminal = Snacks.terminal.open(command, {
    cwd = root,
    interactive = false,
    start_insert = false,
    win = {
      border = "rounded",
      title = " " .. title .. " ",
      title_pos = "center",
      padding = { top = 1, bottom = 1, left = 2, right = 2 },
    },
  })
end

local function run_gradle_task(task, label)
  vim.cmd("silent! write")
  local root = project_root()
  if not root then
    vim.notify("No Gradle or Maven Kotlin project found", vim.log.levels.ERROR)
    return
  end
  local gradle = gradle_command(root)
  if not gradle then
    vim.notify("Gradle is unavailable and this project has no ./gradlew", vim.log.levels.ERROR)
    return
  end
  run_terminal(gradle .. " " .. task, root, label)
end

local function choose_gradle_task()
  local tasks = {
    { label = "Run application", task = "run" },
    { label = "Run tests", task = "test" },
    { label = "Build project", task = "build" },
    { label = "Clean build", task = "clean build" },
    { label = "List tasks", task = "tasks" },
  }
  vim.ui.select(tasks, {
    prompt = "Kotlin / Gradle task:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      run_gradle_task(choice.task, choice.label)
    end
  end)
end

local function current_kotlin_main_class()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.filetype ~= "kotlin" then
    return nil
  end
  if not file:match("%.kt$") or file:match("%.kts$") then
    return nil
  end

  local has_main = false
  local package_name
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if not package_name then
      package_name = line:match("^%s*package%s+([%w_.]+)%s*;?%s*$")
    end
    if line:match("^%s*fun%s+main%s*%(") then
      has_main = true
    end
  end

  if not has_main then
    return nil
  end

  local filename = vim.fn.fnamemodify(file, ":t:r")
  local class_name = filename:gsub("[^%w_]", "") .. "Kt"
  if package_name and package_name ~= "" then
    return package_name .. "." .. class_name
  end
  return class_name
end

local function gradle_task_for_current_file(root)
  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  local relative = vim.fs.relpath(root, file)
  if not relative then
    return "runJavaMain"
  end

  local module = relative:match("^([^/]+)/src/main/kotlin/")
  if module and vim.fn.filereadable(root .. "/" .. module .. "/build.gradle.kts") == 1 then
    return ":" .. module .. ":runJavaMain"
  end

  return "runJavaMain"
end

local function run_current_kotlin_file()
  vim.cmd("silent! write")
  local main_class = current_kotlin_main_class()
  if not main_class then
    vim.notify("Current Kotlin file does not define a top-level main()", vim.log.levels.WARN)
    return
  end

  local root = project_root()
  if not root then
    vim.notify("No Gradle Kotlin project found", vim.log.levels.ERROR)
    return
  end
  local gradle = gradle_command(root)
  if not gradle then
    vim.notify("Gradle is unavailable and this project has no ./gradlew", vim.log.levels.ERROR)
    return
  end

  local task = gradle_task_for_current_file(root)
  run_terminal(
    gradle .. " " .. task .. " -PmainClass=" .. vim.fn.shellescape(main_class),
    root,
    "Run " .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
  )
end

local function choose_kotlin_run_target()
  local options = {
    { label = "Current file", run = run_current_kotlin_file },
    {
      label = "Default application",
      run = function()
        run_gradle_task("run", "Run Kotlin application")
      end,
    },
  }

  vim.ui.select(options, {
    prompt = "Run Kotlin:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      choice.run()
    end
  end)
end

local function reopen_last_terminal()
  if last_terminal then
    last_terminal:toggle()
  else
    vim.notify("No previous Kotlin task", vim.log.levels.INFO)
  end
end

local function kotlin_code_action_matches(action, terms)
  local title = (action.title or ""):lower()
  for _, term in ipairs(terms) do
    if title:find(term, 1, true) then
      return true
    end
  end
  return false
end

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function kotlin_member_signature(line)
  local normalized = line:gsub("^(%s*)abstract%s+fun", "%1fun")
  local indent, name, params, return_type =
    normalized:match("^(%s*)fun%s+([%w_]+)%s*%(([^)]*)%)%s*:%s*([%w_?.<>]+)")
  if not name then
    name, params, return_type = normalized:match("^%s*fun%s+([%w_]+)%s*%(([^)]*)%)%s*:%s*([%w_?.<>]+)")
  end
  if not name then
    name, params = normalized:match("^%s*fun%s+([%w_]+)%s*%(([^)]*)%)")
  end
  if not name then
    return nil
  end
  return {
    indent = indent or "",
    name = name,
    params = trim(params or ""),
    return_type = return_type and trim(return_type) or "Unit",
  }
end

local function find_block_end(lines, start_idx)
  local depth = 0
  local started = false
  for idx = start_idx, #lines do
    for char in lines[idx]:gmatch("[{}]") do
      if char == "{" then
        depth = depth + 1
        started = true
      else
        depth = depth - 1
        if started and depth == 0 then
          return idx
        end
      end
    end
  end
  return nil
end

local function collect_kotlin_types(lines)
  local types = {}
  for idx, line in ipairs(lines) do
    local kind, name, parents = line:match("^%s*(interface)%s+([%w_]+)%s*:?(.-)%s*{")
    if not kind then
      local normalized = line:gsub("^%s*open%s+", ""):gsub("^%s*abstract%s+", "")
      kind, name, parents = normalized:match("^%s*(class)%s+([%w_]+)[^(%s{]*%s*(.-)%s*{")
    end
    if kind and name then
      local end_idx = find_block_end(lines, idx)
      if end_idx then
        local members = {}
        for member_idx = idx + 1, end_idx - 1 do
          local member = kotlin_member_signature(lines[member_idx])
          if member and (kind == "interface" or lines[member_idx]:find("^%s*abstract%s+fun")) then
            table.insert(members, member)
          end
        end
        types[name] = {
          kind = kind,
          start_idx = idx,
          end_idx = end_idx,
          parents = parents or "",
          members = members,
        }
      end
    end
  end
  return types
end

local function parent_type_names(parents)
  local names = {}
  parents = (parents or ""):gsub("%b()", "")
  for name in parents:gmatch("([%a_][%w_]*)") do
    if name ~= "constructor" and name ~= "super" then
      table.insert(names, name)
    end
  end
  return names
end

local function collect_required_members(types, type_name, seen)
  seen = seen or {}
  if seen[type_name] then
    return {}
  end
  seen[type_name] = true

  local type_info = types[type_name]
  if not type_info then
    return {}
  end

  local members = {}
  for _, parent in ipairs(parent_type_names(type_info.parents)) do
    for _, member in ipairs(collect_required_members(types, parent, seen)) do
      table.insert(members, member)
    end
    if types[parent] then
      for _, member in ipairs(types[parent].members) do
        table.insert(members, member)
      end
    end
  end
  return members
end

local function current_kotlin_class(lines)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local types = collect_kotlin_types(lines)
  local best
  for name, type_info in pairs(types) do
    if type_info.kind == "class" and type_info.start_idx <= cursor and cursor <= type_info.end_idx then
      if not best or type_info.start_idx > best.start_idx then
        best = vim.tbl_extend("force", { name = name }, type_info)
      end
    end
  end
  return best, types
end

local function implement_kotlin_members_locally()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local class_info, types = current_kotlin_class(lines)
  if not class_info then
    vim.notify("Place the cursor inside a Kotlin class", vim.log.levels.WARN)
    return
  end

  local existing = {}
  for idx = class_info.start_idx + 1, class_info.end_idx - 1 do
    local member = kotlin_member_signature(lines[idx])
    if member then
      existing[member.name] = true
    end
  end

  local missing = {}
  for _, member in ipairs(collect_required_members(types, class_info.name)) do
    if not existing[member.name] then
      existing[member.name] = true
      table.insert(missing, member)
    end
  end

  if vim.tbl_isempty(missing) then
    vim.notify("No missing Kotlin members found for " .. class_info.name, vim.log.levels.INFO)
    return
  end

  local insert = { "" }
  for idx, member in ipairs(missing) do
    table.insert(insert, "    override fun " .. member.name .. "(" .. member.params .. "): " .. member.return_type .. " {")
    table.insert(insert, '        TODO("Not yet implemented")')
    table.insert(insert, "    }")
    if idx < #missing then
      table.insert(insert, "")
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, class_info.end_idx - 1, class_info.end_idx - 1, false, insert)
  vim.notify("Implemented " .. #missing .. " Kotlin member(s)", vim.log.levels.INFO)
end

local kotlin_action_kinds = { "quickfix", "refactor.rewrite", "source" }

local function kotlin_code_action_params()
  local params = vim.lsp.util.make_range_params(0, "utf-16")
  params.context = {
    diagnostics = vim.diagnostic.get(0),
    only = kotlin_action_kinds,
  }
  return params
end

local function apply_kotlin_code_action(action, client)
  if
    client
    and client.supports_method
    and client:supports_method("codeAction/resolve")
    and type(client.request_sync) == "function"
    and not action.edit
    and not action.command
  then
    local resolved = client:request_sync("codeAction/resolve", action, 1000, 0)
    action = (resolved and resolved.result) or action
  end

  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client and client.offset_encoding or "utf-16")
  end

  local command = action.command
  if type(command) == "table" then
    vim.lsp.buf.execute_command(command)
  elseif type(command) == "string" then
    vim.lsp.buf.execute_command({
      command = command,
      arguments = action.arguments,
    })
  end
end

local function run_kotlin_code_action(terms)
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/codeAction",
  })

  if vim.tbl_isempty(clients) then
    implement_kotlin_members_locally()
    return
  end

  local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", kotlin_code_action_params(), 1000) or {}
  for client_id, response in pairs(responses) do
    local actions = response.result or {}
    for _, action in ipairs(actions) do
      if not action.disabled and kotlin_code_action_matches(action, terms) then
        local client = vim.lsp.get_client_by_id(client_id)
        apply_kotlin_code_action(action, client)
        return
      end
    end
  end

  implement_kotlin_members_locally()
end

local function implement_kotlin_members()
  run_kotlin_code_action({
    "implement",
    "implement members",
    "implement missing",
    "add missing",
    "abstract members",
  })
end

local function override_kotlin_members()
  run_kotlin_code_action({
    "override",
    "override members",
    "implement members",
    "abstract members",
  })
end

local function set_kotlin_highlights()
  vim.api.nvim_set_hl(0, "@kotlin.lambda.brace", { bold = true })
  vim.api.nvim_set_hl(0, "@kotlin.lambda.brace.kotlin", { bold = true })
end

set_kotlin_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_kotlin_highlights,
})

local function jump_to_lsp_item(item)
  if not item or not item.filename then
    return
  end

  local target = vim.fn.fnamemodify(item.filename, ":p")
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p") == target then
      vim.api.nvim_set_current_win(win)
      break
    end
  end

  if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p") ~= target then
    vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
  end

  local line_count = math.max(vim.api.nvim_buf_line_count(0), 1)
  local lnum = math.min(math.max(item.lnum or 1, 1), line_count)
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  local col = math.min(math.max((item.col or 1) - 1, 0), #line)

  vim.api.nvim_win_set_cursor(0, { lnum, col })
  vim.cmd("normal! zzzv")
end

local stdlib_sources = {
  Any = "commonMain/kotlin/Any.kt",
  Annotation = "commonMain/kotlin/Annotation.kt",
  Array = "commonMain/kotlin/Array.kt",
  Boolean = "commonMain/kotlin/Boolean.kt",
  Byte = "commonMain/kotlin/Primitives.kt",
  Char = "commonMain/kotlin/Char.kt",
  CharSequence = "commonMain/kotlin/CharSequence.kt",
  Comparable = "commonMain/kotlin/Comparable.kt",
  Double = "commonMain/kotlin/Primitives.kt",
  Enum = "commonMain/kotlin/Enum.kt",
  Float = "commonMain/kotlin/Primitives.kt",
  Int = "commonMain/kotlin/Primitives.kt",
  Long = "commonMain/kotlin/Primitives.kt",
  Nothing = "commonMain/kotlin/Nothing.kt",
  Number = "commonMain/kotlin/Number.kt",
  Short = "commonMain/kotlin/Primitives.kt",
  String = "commonMain/kotlin/String.kt",
  Throwable = "commonMain/kotlin/Throwable.kt",
  Unit = "commonMain/kotlin/Unit.kt",
}

local function kotlin_stdlib_sources_jar()
  local jars = vim.fn.glob(
    vim.fn.expand("~/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-stdlib/*/*/kotlin-stdlib-*-sources.jar"),
    false,
    true
  )
  table.sort(jars)
  return jars[#jars]
end

local function goto_kotlin_stdlib_source(symbol)
  local entry = stdlib_sources[symbol]
  if not entry then
    return false
  end

  local jar = kotlin_stdlib_sources_jar()
  if not jar then
    return false
  end

  local target_dir = vim.fn.stdpath("cache") .. "/kotlin-stdlib-sources"
  local target = target_dir .. "/" .. entry
  if vim.fn.filereadable(target) ~= 1 then
    vim.fn.mkdir(target_dir, "p")
    local result = vim.system({ "jar", "xf", jar, entry }, { cwd = target_dir }):wait()
    if result.code ~= 0 or vim.fn.filereadable(target) ~= 1 then
      vim.notify("Could not extract Kotlin stdlib source for " .. symbol, vim.log.levels.WARN)
      return false
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(target))
  local pattern = [[\C\Vclass ]] .. vim.fn.escape(symbol, [[\]])
  local lnum = vim.fn.search(pattern, "nw")
  if lnum == 0 then
    lnum = vim.fn.search([[\C\Vinterface ]] .. vim.fn.escape(symbol, [[\]]), "nw")
  end
  if lnum > 0 then
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
    vim.cmd("normal! zzzv")
  end
  return true
end

local function kotlin_definition()
  local bufnr = vim.api.nvim_get_current_buf()
  local symbol = vim.fn.expand("<cword>")
  local method = "textDocument/definition"
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = method })
  if vim.tbl_isempty(clients) then
    vim.notify("No definition provider found", vim.log.levels.INFO)
    return
  end

  local items = {}
  local remaining = #clients
  for _, client in ipairs(clients) do
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    client:request(method, params, function(err, result)
      if err then
        vim.notify(err.message or tostring(err), vim.log.levels.ERROR)
      elseif result and not vim.tbl_isempty(result) then
        local locations = vim.tbl_islist(result) and result or { result }
        vim.list_extend(items, vim.lsp.util.locations_to_items(locations, client.offset_encoding))
      end

      remaining = remaining - 1
      if remaining == 0 then
        vim.schedule(function()
          if vim.tbl_isempty(items) then
            if goto_kotlin_stdlib_source(symbol) then
              return
            end
            vim.notify("No definition found", vim.log.levels.INFO)
            return
          end

          if #items > 1 then
            vim.fn.setqflist({}, " ", {
              title = "Definitions",
              items = items,
            })
            vim.cmd("botright copen")
            return
          end

          jump_to_lsp_item(items[1])
        end)
      end
    end, bufnr)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "kotlin",
  callback = function(ev)
    vim.keymap.set("n", "gd", kotlin_definition, {
      buffer = ev.buf,
      desc = "Goto Definition",
    })
  end,
})

local function is_filtered_kotlin_lsp_diagnostic(diagnostic)
  if diagnostic.code == "UNRESOLVED_REFERENCE" and diagnostic.message == "Unresolved reference: println" then
    return true
  end

  return diagnostic.code == "INCOMPATIBLE_CLASS"
    and diagnostic.message:find("metadata version is 2.3.0", 1, true) ~= nil
    and diagnostic.message:find("compiler version 2.1.0", 1, true) ~= nil
    and diagnostic.message:find("/org.jetbrains.kotlin/kotlin-stdlib/2.3.20/", 1, true) ~= nil
end

if not vim.g.kotlin_lsp_filtered_diagnostics then
  vim.g.kotlin_lsp_filtered_diagnostics = true
  local publish_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]

  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client and client.name == "kotlin_language_server" and result and result.diagnostics then
      result = vim.deepcopy(result)
      result.diagnostics = vim.tbl_filter(function(diagnostic)
        return not is_filtered_kotlin_lsp_diagnostic(diagnostic)
      end, result.diagnostics)
    end

    return publish_diagnostics(err, result, ctx, config)
  end
end

local function valid_package_name(name)
  if name:sub(1, 1) == "." or name:sub(-1) == "." or name:find("..", 1, true) then
    return false
  end
  for segment in name:gmatch("[^.]+") do
    if not segment:match("^[%a_][%w_]*$") then
      return false
    end
  end
  return name ~= ""
end

local java_source_sets_block = [[
sourceSets {
    main {
        java {
            srcDir("src/main/kotlin")
        }
    }
}
]]

local java_run_task_block = [[
tasks.register<JavaExec>("runJavaMain") {
    group = "application"
    description = "Runs a Java main class from this project. Pass -PmainClass=<fully.qualified.ClassName>."

    mainClass.set(providers.gradleProperty("mainClass"))
    classpath = sourceSets.main.get().runtimeClasspath
}
]]

local function add_java_support_to_kotlin_project(target)
  local build_file = target .. "/app/build.gradle.kts"
  if vim.fn.filereadable(build_file) ~= 1 then
    build_file = target .. "/build.gradle.kts"
  end
  if vim.fn.filereadable(build_file) ~= 1 then
    return false, "Could not find build.gradle.kts"
  end

  local lines = vim.fn.readfile(build_file)
  local content = table.concat(lines, "\n") .. "\n"
  local changed = false

  if not content:find("srcDir%(%s*\"src/main/kotlin\"%s*%)") then
    local marker = "\n// Apply a specific Java toolchain"
    if content:find(marker, 1, true) then
      content = content:gsub(marker, "\n" .. java_source_sets_block .. marker, 1)
    else
      content = content .. "\n" .. java_source_sets_block
    end
    changed = true
  end

  if not content:find("tasks%.register<JavaExec>%(%s*\"runJavaMain\"%s*%)") then
    content = content:gsub("%s+$", "") .. "\n\n" .. java_run_task_block .. "\n"
    changed = true
  end

  if changed then
    vim.fn.writefile(vim.split(content, "\n", { plain = true }), build_file)
  end

  return true, build_file
end

local function module_package_segment(name)
  local segment = name:lower():gsub("[^%w_]", "")
  if segment == "" or not segment:match("^[%a_]") then
    segment = "module" .. segment
  end
  return segment
end

local function package_path(package_name)
  return package_name:gsub("%.", "/")
end

local function gradle_settings_file(root)
  local kotlin_settings = root .. "/settings.gradle.kts"
  if vim.fn.filereadable(kotlin_settings) == 1 then
    return kotlin_settings, "kotlin"
  end

  local groovy_settings = root .. "/settings.gradle"
  if vim.fn.filereadable(groovy_settings) == 1 then
    return groovy_settings, "groovy"
  end

  return nil, nil
end

local function gradle_module_included(settings_content, module_name)
  local escaped = vim.pesc(module_name)
  return settings_content:find('include%(%s*"' .. escaped .. '"%s*%)') ~= nil
    or settings_content:find("include%(%s*'" .. escaped .. "'%s*%)") ~= nil
    or settings_content:find('include%s+"' .. escaped .. '"') ~= nil
    or settings_content:find("include%s+'" .. escaped .. "'") ~= nil
end

local function append_gradle_module_include(settings_file, settings_kind, module_name)
  local lines = vim.fn.readfile(settings_file)
  local content = table.concat(lines, "\n")
  if gradle_module_included(content, module_name) then
    return true
  end

  local include_line = settings_kind == "groovy" and "include '" .. module_name .. "'" or 'include("' .. module_name .. '")'
  table.insert(lines, include_line)
  vim.fn.writefile(lines, settings_file)
  return true
end

local function kotlin_module_build_gradle(package_name)
  local main_class = package_name .. ".MainKt"
  return {
    "plugins {",
    "    alias(libs.plugins.kotlin.jvm)",
    "    application",
    "}",
    "",
    "repositories {",
    "    mavenCentral()",
    "}",
    "",
    "dependencies {",
    "    testImplementation(libs.junit.jupiter)",
    "    testRuntimeOnly(\"org.junit.platform:junit-platform-launcher\")",
    "    implementation(libs.guava)",
    "}",
    "",
    "sourceSets {",
    "    main {",
    "        java {",
    "            srcDir(\"src/main/kotlin\")",
    "        }",
    "    }",
    "}",
    "",
    "java {",
    "    toolchain {",
    "        languageVersion = JavaLanguageVersion.of(21)",
    "    }",
    "}",
    "",
    "application {",
    '    mainClass = "' .. main_class .. '"',
    "}",
    "",
    "tasks.named<Test>(\"test\") {",
    "    useJUnitPlatform()",
    "}",
    "",
    "tasks.register<JavaExec>(\"runJavaMain\") {",
    "    group = \"application\"",
    '    description = "Runs a Java main class from this project. Pass -PmainClass=<fully.qualified.ClassName>."',
    "",
    "    mainClass.set(providers.gradleProperty(\"mainClass\"))",
    "    classpath = sourceSets.main.get().runtimeClasspath",
    "}",
    "",
  }
end

local function kotlin_module_main(package_name)
  return {
    "package " .. package_name,
    "",
    "fun main() {",
    '    println("Hello from ' .. package_name .. '")',
    "}",
    "",
  }
end

local function kotlin_module_test(package_name)
  return {
    "package " .. package_name,
    "",
    "import org.junit.jupiter.api.Assertions.assertTrue",
    "import org.junit.jupiter.api.Test",
    "",
    "class MainTest {",
    "    @Test",
    "    fun moduleLoads() {",
    "        assertTrue(true)",
    "    }",
    "}",
    "",
  }
end

local function create_kotlin_module_files(root, module_name, package_name)
  local module_root = root .. "/" .. module_name
  local source_root = module_root .. "/src/main/kotlin/" .. package_path(package_name)
  local test_root = module_root .. "/src/test/kotlin/" .. package_path(package_name)

  vim.fn.mkdir(source_root, "p")
  vim.fn.mkdir(test_root, "p")
  vim.fn.writefile(kotlin_module_build_gradle(package_name), module_root .. "/build.gradle.kts")
  vim.fn.writefile(kotlin_module_main(package_name), source_root .. "/Main.kt")
  vim.fn.writefile(kotlin_module_test(package_name), test_root .. "/MainTest.kt")

  return source_root .. "/Main.kt"
end

local function create_kotlin_module()
  local root = gradle_build_root()
  if not root then
    vim.notify("No Gradle settings file found above current file", vim.log.levels.ERROR)
    return
  end

  local settings_file, settings_kind = gradle_settings_file(root)
  if not settings_file then
    vim.notify("Could not find settings.gradle.kts or settings.gradle", vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "Kotlin module name: " }, function(module_name)
    if not module_name or module_name == "" then
      return
    end
    if not module_name:match("^[%w_.-]+$") then
      vim.notify("Use only letters, numbers, '.', '_' or '-' in the module name", vim.log.levels.ERROR)
      return
    end

    local module_root = root .. "/" .. module_name
    if vim.fn.isdirectory(module_root) == 1 or vim.fn.filereadable(module_root) == 1 then
      vim.notify(module_root .. " already exists", vim.log.levels.ERROR)
      return
    end

    local settings_content = table.concat(vim.fn.readfile(settings_file), "\n")
    if gradle_module_included(settings_content, module_name) then
      vim.notify(module_name .. " is already included in " .. vim.fn.fnamemodify(settings_file, ":t"), vim.log.levels.ERROR)
      return
    end

    local package_default = "com.huerta." .. module_package_segment(module_name)
    vim.ui.input({ prompt = "Package: ", default = package_default }, function(package_name)
      if not package_name or package_name == "" then
        return
      end
      if not valid_package_name(package_name) then
        vim.notify("Invalid Kotlin package name", vim.log.levels.ERROR)
        return
      end

      local main_file = create_kotlin_module_files(root, module_name, package_name)
      append_gradle_module_include(settings_file, settings_kind, module_name)
      vim.notify("Created Kotlin module: " .. module_name, vim.log.levels.INFO)
      vim.cmd("edit " .. vim.fn.fnameescape(main_file))
    end)
  end)
end

local function create_project()
  local parent = vim.uv.cwd()
  vim.ui.input({ prompt = "Kotlin project name: " }, function(name)
    if not name or name == "" then
      return
    end
    if not name:match("^[%w_.-]+$") then
      vim.notify("Use only letters, numbers, '.', '_' or '-' in the project name", vim.log.levels.ERROR)
      return
    end
    local target = parent .. "/" .. name
    if vim.fn.isdirectory(target) == 1 or vim.fn.filereadable(target) == 1 then
      vim.notify(target .. " already exists", vim.log.levels.ERROR)
      return
    end

    local package_segment = name:lower():gsub("[^%w_]", "")
    if package_segment == "" or not package_segment:match("^[%a_]") then
      package_segment = "app" .. package_segment
    end
    local package_default = "com.example." .. package_segment
    vim.ui.input({ prompt = "Package: ", default = package_default }, function(package_name)
      if not package_name or package_name == "" then
        return
      end
      if not valid_package_name(package_name) then
        vim.notify("Invalid Kotlin package name", vim.log.levels.ERROR)
        return
      end
      if vim.fn.executable("gradle") ~= 1 then
        vim.notify("Install Gradle before creating a project", vim.log.levels.ERROR)
        return
      end

      vim.fn.mkdir(target, "p")
      local args = {
        "init",
        "--type",
        "kotlin-application",
        "--dsl",
        "kotlin",
        "--test-framework",
        "junit-jupiter",
        "--no-split-project",
        "--use-defaults",
        "--project-name",
        name,
        "--package",
        package_name,
      }
      vim.notify("Creating Kotlin project: " .. name, vim.log.levels.INFO)
      vim.system({ "gradle", unpack(args) }, { cwd = target, text = true }, function(result)
        vim.schedule(function()
          if result.code ~= 0 then
            local message = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
            vim.notify(message ~= "" and message or "Gradle project creation failed", vim.log.levels.ERROR)
            return
          end

          local ok, detail = add_java_support_to_kotlin_project(target)
          if not ok then
            vim.notify("Kotlin project created, but Java support was not added: " .. detail, vim.log.levels.WARN)
            return
          end

          vim.notify("Kotlin project created with Java run support: " .. detail, vim.log.levels.INFO)
          vim.cmd("edit " .. vim.fn.fnameescape(target))
        end)
      end)
    end)
  end)
end

vim.keymap.set("n", "<leader>Kp", create_project, { desc = "Create Gradle Kotlin project" })
vim.keymap.set("n", "<leader>Kn", create_kotlin_module, { desc = "Create Kotlin module" })
vim.keymap.set("n", "<leader>Ki", implement_kotlin_members, { desc = "Implement members" })
vim.keymap.set("n", "<leader>Ko", override_kotlin_members, { desc = "Override members" })
vim.keymap.set("n", "<leader>Kr", choose_kotlin_run_target, { desc = "Run Kotlin" })
vim.keymap.set("n", "<leader>Kt", function()
  run_gradle_task("test", "Test Kotlin project")
end, { desc = "Run tests" })
vim.keymap.set("n", "<leader>Kb", function()
  run_gradle_task("build", "Build Kotlin project")
end, { desc = "Build project" })
vim.keymap.set("n", "<leader>Km", choose_gradle_task, { desc = "Choose Gradle task" })
vim.keymap.set("n", "<leader>Kl", reopen_last_terminal, { desc = "Reopen last task" })

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "kotlin-language-server",
        "kotlin-debug-adapter",
        "ktlint",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {
          keys = {
            { "gd", kotlin_definition, desc = "Goto Definition" },
            { "<leader>Kn", create_kotlin_module, desc = "Create Kotlin module" },
            { "<leader>Ki", implement_kotlin_members, desc = "Implement members" },
            { "<leader>Ko", override_kotlin_members, desc = "Override members" },
          },
        },
        -- kotlin-lsp is an expiring pre-alpha IntelliJ build. Keep it disabled
        -- until it can initialize reliably instead of leaving Kotlin without
        -- completion whenever a bundled build expires or exits during startup.
        kotlin_lsp = { enabled = false },
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>K", group = "Kotlin", icon = "" },
        { "<leader>Kp", create_project, desc = "Create Gradle Kotlin project" },
        { "<leader>Kn", create_kotlin_module, desc = "Create Kotlin module" },
        { "<leader>Ki", implement_kotlin_members, desc = "Implement members" },
        { "<leader>Ko", override_kotlin_members, desc = "Override members" },
        { "<leader>Kr", choose_kotlin_run_target, desc = "Run Kotlin" },
        { "<leader>Kt", desc = "Run tests" },
        { "<leader>Kb", desc = "Build project" },
        { "<leader>Km", choose_gradle_task, desc = "Choose Gradle task" },
        { "<leader>Kl", reopen_last_terminal, desc = "Reopen last task" },
      },
    },
  },
}
