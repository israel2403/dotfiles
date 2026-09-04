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

local function format_html()
  local ok, conform = pcall(require, "conform")
  if not ok then
    vim.notify("conform.nvim is unavailable", vim.log.levels.ERROR)
    return
  end

  local formatted, err = pcall(conform.format, {
    bufnr = 0,
    async = false,
    formatters = { "prettier_html" },
    lsp_format = "never",
  })
  if not formatted then
    vim.notify("HTML formatting failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Keep the closing bracket of multi-attribute paired tags with the final
  -- attribute. Prettier's standalone `/>` for void elements remains unchanged.
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for index = #lines, 2, -1 do
    if lines[index]:match("^%s*>%s*$") then
      lines[index - 1] = lines[index - 1] .. ">"
      table.remove(lines, index)
    end
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  if vim.bo.modified then
    vim.cmd.write()
  end
  vim.notify("HTML formatted with Prettier", vim.log.levels.INFO)
end

local function format_current_buffer()
  if find_maven_root() then
    run_spotless_apply()
  elseif vim.bo.filetype == "html" then
    format_html()
  else
    vim.notify("F4 formatting supports Maven projects and HTML files", vim.log.levels.WARN)
  end
end

vim.api.nvim_create_user_command("MavenSpotlessApply", run_spotless_apply, { desc = "Run mvn spotless:apply" })
vim.api.nvim_create_user_command("FormatWithF4", format_current_buffer, {
  desc = "Format a Maven project with Spotless or an HTML file with Prettier",
})

vim.keymap.set({ "n", "x" }, "<M-f>", format_current_buffer, { desc = "Format (Spotless or HTML)" })
vim.keymap.set("i", "<M-f>", function()
  vim.cmd.stopinsert()
  vim.schedule(format_current_buffer)
end, { desc = "Format (Spotless or HTML)" })
vim.keymap.set({ "n", "x" }, "<F4>", format_current_buffer, { desc = "Format (Spotless or HTML)" })
vim.keymap.set("i", "<F4>", function()
  vim.cmd.stopinsert()
  vim.schedule(format_current_buffer)
end, { desc = "Format (Spotless or HTML)" })
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
        { "<M-f>", format_current_buffer, desc = "Format (Spotless or HTML)" },
        { "<F4>", format_current_buffer, desc = "Format (Spotless or HTML)" },
        { "<leader>Jf", run_spotless_apply, desc = "Maven Spotless Apply" },
      },
    },
  },
}
