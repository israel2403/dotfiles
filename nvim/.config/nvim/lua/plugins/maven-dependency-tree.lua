-- Local plugin: ~/projects/personal/nvim-plugins/maven-dependency-tree.nvim
--
-- The plugin lives outside this repo as a git project; Lazy loads it via
-- the `dir =` field so changes there are picked up immediately (no sync).
--
-- It exposes three user commands (defined in plugin/maven_dependency_tree.lua
-- inside the plugin, which is the path Neovim auto-sources):
--     :MavenDependencyTree           open the tree
--     :MavenDependencyTreeRefresh    re-run mvn dependency:tree and redraw
--     :MavenDependencyTreeClose      close the split
-- Use `cmd = {...}` so the plugin is loaded on first command invocation
-- (faster startup) and `ft = "xml"` so it also loads automatically when you
-- open a pom.xml.
return {
  {
    dir = vim.fn.expand("~/projects/personal/nvim-plugins/maven-dependency-tree.nvim"),
    name = "maven-dependency-tree",
    cmd = {
      "MavenDependencyTree",
      "MavenDependencyTreeRefresh",
      "MavenDependencyTreeClose",
    },
    ft = { "xml" },
    keys = {
      {
        "<leader>cM",
        "<cmd>MavenDependencyTree<cr>",
        desc = "Maven Dependency Tree",
      },
    },
    config = function()
      require("maven_dependency_tree").setup({
        window = "split",
        split_direction = "right",
        split_width = 70,
      })
    end,
  },
}
