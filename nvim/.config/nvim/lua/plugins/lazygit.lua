-- lazygit.lua
-- LazyVim already wires the two main mappings via Snacks:
--     <leader>gg  Lazygit (Root Dir)
--     <leader>gG  Lazygit (cwd)
-- This plugin spec adds two missing convenience mappings that hit the
-- snacks.lazygit module directly:
--     <leader>gH  Lazygit log view (full log inside lazygit's UI)
--     <leader>gC  Lazygit log of the CURRENT FILE (history just for this file)
--
-- Editor integration: ~/.config/lazygit/config.yml (stowed via the `lazygit`
-- package) wires lazygit's `os.edit*` to a small `lazygit-edit` shim. When
-- lazygit is launched from inside nvim, pressing Enter on a file opens it as
-- a new tab in the SAME nvim instance instead of nesting a new nvim inside
-- lazygit. See scripts/.local/bin/lazygit-edit.
--
-- Theme integration is automatic: snacks.lazygit regenerates a theme YAML
-- on every ColorScheme event and chains it via LG_CONFIG_FILE.

return {
  -- We don't pull in a separate lazygit.nvim plugin -- snacks.nvim already
  -- ships the integration and is the LazyVim default. We just (a) make sure
  -- snacks is loaded with the lazygit module enabled and (b) add our extra
  -- keymaps as an `optional = true` override.
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      lazygit = {
        -- Pass through any future tweaks here. Defaults are already good:
        -- the theme is regenerated from the active colorscheme on each open.
      },
    },
    keys = {
      {
        "<leader>gH",
        function() Snacks.lazygit.log() end,
        desc = "Lazygit Log (view)",
      },
      {
        "<leader>gC",
        function() Snacks.lazygit.log_file() end,
        desc = "Lazygit Log (current file)",
      },
    },
  },

  -- Give which-key a clean group label for everything under <leader>g.
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>g", group = "Git", icon = "" },
      },
    },
  },
}
