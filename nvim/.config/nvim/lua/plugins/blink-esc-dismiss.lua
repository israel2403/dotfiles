-- blink-esc-dismiss.lua
-- Make <Esc> and the TeamViewer-friendly `jk` chord in insert mode "smart":
--   * If blink.cmp is showing a completion menu or ghost-text suggestion,
--     hide it and STAY in insert mode.
--   * If nothing is shown, fall through to the regular <Esc> behaviour
--     (leave insert mode). For `jk`, fallback uses the insert-mode keymap
--     in lua/config/keymaps.lua.
--
-- Why two actions? blink.cmp evaluates each entry in the action list in
-- order. Each action returns true (handled, stop) or false (try next).
--   - "hide"     returns true only when there's something to dismiss, so
--                 the keypress is consumed and you stay in insert mode.
--   - "fallback" runs whatever <Esc> would have done outside blink.cmp,
--                 i.e. the standard <Esc> binding (leave insert mode).
--
-- LazyVim's default preset already binds <C-e> to "hide". This plugin
-- spec is purely additive: it does not change <C-e>, <C-y>, <C-n>, etc.,
-- so muscle memory for the rest of the menu navigation is preserved.

return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<Esc>"] = { "hide", "fallback" },
        ["jk"] = { "hide", "fallback" },
      },
    },
  },
}
