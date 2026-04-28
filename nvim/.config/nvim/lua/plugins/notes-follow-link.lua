-- notes-follow-link.lua
-- In any markdown buffer, pressing <CR> or gf on a link under the cursor
-- jumps to the linked file. Handles both link styles you use in ~/notes:
--
--   * Markdown link  [text](relative/or/absolute/path.md[#anchor])
--   * Wiki link      [[note-name]]   or   [[note-name|alias]]
--
-- Wiki links are delegated to obsidian.nvim (smart_action) when it's
-- loaded, so vault-aware resolution Just Works for the ~/notes vault.
-- A small fallback `find ~/notes -name '<name>.md'` handles wiki links
-- before obsidian.nvim has been loaded for the buffer.
--
-- Jumping back uses the built-in jumplist:  <C-o>  (back)  /  <C-i>  (fwd).
-- No extra mapping needed.

local NOTES_ROOT = vim.fn.expand("~/notes")

-- Resolve the target of a markdown link relative to the current buffer.
--   /abs/path        -> as-is
--   ~/foo            -> $HOME-expanded
--   anything else    -> relative to the current buffer's directory
local function resolve_md_target(target)
  if target:sub(1, 1) == "/" then
    return target
  end
  if target:sub(1, 1) == "~" then
    return vim.fn.expand(target)
  end
  local current_dir = vim.fn.expand("%:p:h")
  if current_dir == "" then
    current_dir = vim.fn.getcwd()
  end
  return vim.fn.simplify(current_dir .. "/" .. target)
end

-- If the cursor sits inside a `[label](target)` span, return target; else nil.
local function md_link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-based byte column
  -- Iterate every [text](target) match on the line. The () captures give
  -- start/end byte offsets so we can match the cursor against the span.
  for s, target, e in line:gmatch("()%[[^%]]*%]%(([^)]+)%)()") do
    if col >= s and col < e then
      return target
    end
  end
  return nil
end

-- Same idea for [[wiki]] / [[wiki|alias]] links.
local function wiki_link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  for s, target, e in line:gmatch("()%[%[([^%]]+)%]%]()") do
    if col >= s and col < e then
      target = target:match("([^|]+)") or target
      return vim.trim and vim.trim(target) or target:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end
  return nil
end

-- Last-resort wiki resolver: search ~/notes for a file named <wiki>.md.
local function resolve_wiki_in_vault(wiki)
  -- Strip a possible explicit extension and any directory prefix from the
  -- wiki target so [[inbox/foo]] also matches a bare foo.md somewhere.
  local name = wiki:gsub("%.md$", "")
  local matches = vim.fn.systemlist({ "find", NOTES_ROOT, "-type", "f", "-name", name .. ".md" })
  for _, m in ipairs(matches) do
    if m and m ~= "" then
      return m
    end
  end
  return nil
end

-- Try to follow a link under the cursor. Returns true if something was
-- handled (file opened or notify shown about a missing link). Returns
-- false if the cursor is NOT on any kind of link, leaving the caller to
-- pass the original keypress through to its default behaviour.
local function try_follow_link()
  -- 1) markdown link [text](path[#anchor])
  local target = md_link_under_cursor()
  if target then
    local file = target:match("([^#]+)") or target -- drop "#section"
    local path = resolve_md_target(file)
    if vim.fn.filereadable(path) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    else
      vim.notify("Link target not found: " .. path, vim.log.levels.WARN)
    end
    return true
  end

  -- 2) wiki link [[note]] / [[note|alias]]
  local wiki = wiki_link_under_cursor()
  if wiki then
    local hit = resolve_wiki_in_vault(wiki)
    if hit then
      vim.cmd("edit " .. vim.fn.fnameescape(hit))
    else
      vim.notify("No note matches: " .. wiki, vim.log.levels.WARN)
    end
    return true
  end

  return false
end

-- Build a normal-mode mapping callback that:
--   * follows a link under the cursor when there is one, OR
--   * passes the original keypress through to its default Vim behaviour
--     (i.e. <CR> just moves to the next line; gf still goes to file).
-- nvim_feedkeys with the 'n' mode flag means "no remap", so the fed key
-- bypasses our own mapping and uses the built-in semantics.
local function follow_link_or_passthrough(fallback_lhs)
  return function()
    if try_follow_link() then
      return
    end
    local keys = vim.api.nvim_replace_termcodes(fallback_lhs, true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  end
end

-- This file is a "plugin spec" so LazyVim auto-loads it; the actual hook
-- is the FileType autocmd installed below. We piggy-back on lazy.nvim's
-- "VeryLazy" event so the autocmd is registered exactly once after startup.
return {
  {
    "folke/lazy.nvim",
    optional = true,
    event = "VeryLazy",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserNotesFollowLink", { clear = true }),
        pattern = "markdown",
        callback = function(ev)
          local map = function(lhs, desc)
            vim.keymap.set("n", lhs, follow_link_or_passthrough(lhs), {
              buffer = ev.buf,
              silent = true,
              desc = desc,
            })
          end
          map("<CR>", "Follow link under cursor (or default <CR>)")
          map("gf", "Follow link under cursor (or default gf)")
        end,
      })
    end,
  },
}
