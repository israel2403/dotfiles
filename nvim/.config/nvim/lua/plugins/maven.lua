local function find_maven_root()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.uv.cwd()
  end

  return vim.fs.root(path, "pom.xml")
end

local spotless_plugin = [[    <plugins>
      <plugin>
        <groupId>com.diffplug.spotless</groupId>
        <artifactId>spotless-maven-plugin</artifactId>
        <version>3.8.0</version>
        <configuration>
          <java>
            <googleJavaFormat>
              <version>1.35.0</version>
              <style>GOOGLE</style>
            </googleJavaFormat>
          </java>
        </configuration>
      </plugin>
    </plugins>]]

local function ensure_spotless_plugin(root)
  local pom = root .. "/pom.xml"
  local lines = vim.fn.readfile(pom)
  if vim.tbl_isempty(lines) then
    return false, "Could not read pom.xml"
  end

  local xml = table.concat(lines, "\n")
  if xml:find("<artifactId>spotless%-maven%-plugin</artifactId>", 1, false) then
    return true
  end

  if xml:find("<build>%s*<plugins>", 1, false) then
    xml = xml:gsub("(<build>%s*<plugins>%s*)", "%1" .. spotless_plugin:match("<plugin>.*</plugin>") .. "\n", 1)
  elseif xml:find("<build>", 1, false) then
    xml = xml:gsub("(<build>%s*)", "%1\n" .. spotless_plugin .. "\n", 1)
  elseif xml:find("</project>", 1, false) then
    xml = xml:gsub("%s*</project>%s*$", "\n  <build>\n" .. spotless_plugin .. "\n  </build>\n</project>\n", 1)
  else
    return false, "Could not find </project> in pom.xml"
  end

  vim.fn.writefile(vim.split(xml, "\n", { plain = true }), pom)
  vim.notify("Added Spotless Maven plugin to pom.xml", vim.log.levels.INFO)
  return true
end

local function run_spotless_apply()
  local root = find_maven_root()
  if not root then
    vim.notify("No pom.xml found for Spotless", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.cmd.write()
  end

  local ok, message = ensure_spotless_plugin(root)
  if not ok then
    vim.notify(message, vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.notify("Running mvn spotless:apply", vim.log.levels.INFO)

  vim.system({ "mvn", "-q", "spotless:apply" }, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local message = vim.trim(result.stderr ~= "" and result.stderr or result.stdout)
        vim.notify(message ~= "" and message or "mvn spotless:apply failed", vim.log.levels.ERROR)
        return
      end

      if vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("silent! edit")
        end)
      end

      vim.notify("Spotless applied", vim.log.levels.INFO)
    end)
  end)
end

vim.api.nvim_create_user_command("MavenSpotlessApply", run_spotless_apply, { desc = "Run mvn spotless:apply" })

vim.keymap.set({ "n", "x" }, "<M-f>", run_spotless_apply, { desc = "Maven Spotless Apply" })
vim.keymap.set("i", "<M-f>", function()
  vim.cmd.stopinsert()
  vim.schedule(run_spotless_apply)
end, { desc = "Maven Spotless Apply" })
vim.keymap.set({ "n", "x" }, "<F4>", run_spotless_apply, { desc = "Maven Spotless Apply" })
vim.keymap.set("i", "<F4>", function()
  vim.cmd.stopinsert()
  vim.schedule(run_spotless_apply)
end, { desc = "Maven Spotless Apply" })
vim.keymap.set({ "n", "x" }, "<leader>Jf", run_spotless_apply, { desc = "Maven Spotless Apply" })

return {
  {
    "eatgrass/maven.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("maven").setup()
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<M-f>", run_spotless_apply, desc = "Maven Spotless Apply" },
        { "<F4>", run_spotless_apply, desc = "Maven Spotless Apply" },
        { "<leader>Jf", run_spotless_apply, desc = "Maven Spotless Apply" },
      },
    },
  },
}
