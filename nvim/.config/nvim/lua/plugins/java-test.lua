local function run() require('java-tests').file() end
local function toggle() require('java-tests').toggle() end
vim.api.nvim_create_user_command('JavaTestFile', run, { desc = 'Run Maven test class or Cucumber feature suite' })
vim.api.nvim_create_user_command('JavaTestResults', toggle, { desc = 'Toggle Java test results' })
vim.keymap.set('n', '<leader>JT', run, { desc = 'Test file / Cucumber suite' })
vim.keymap.set('n', '<leader>Jo', toggle, { desc = 'Toggle test results' })
return {
  {
    'folke/which-key.nvim',
    optional = true,
    opts = { spec = {
      { '<leader>JT', run, desc = 'Test file / Cucumber suite' },
      { '<leader>Jo', toggle, desc = 'Toggle test results' },
    } },
  },
}
