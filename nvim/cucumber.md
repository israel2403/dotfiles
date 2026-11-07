# Cucumber / Gherkin

Open a `.feature` file: it uses the `cucumber` filetype and the Cucumber language
server, installed with npm under `~/.local`. The nearest `pom.xml` or
Gradle build is the workspace root, so opening a file from the corpus monorepo
still finds the identity service's Java steps.

- Completion: normal completion menu or `<C-Space>`; step suggestions come from
  saved Cucumber annotations in `src/test/java/**/*.java`.
- Navigation: `gd` on a step jumps to its definition; `K` opens available hover.
- Diagnostics: syntax errors and undefined steps appear through the normal LSP UI.
- Snippets: `feature`, `scenario`, `outline`, `background`; use the completion
  menu to expand and your usual LuaSnip jump keys to fill placeholders.
- Comments use `#`; indentation uses two spaces.
- Check attachment with `:LspInfo`; the server executable is `~/.local/bin/cucumber-language-server`.

Run tests with `<leader>JT` from a Java Cucumber suite or a `.feature` file.
Feature files select the matching `@Suite` / `@SelectClasspathResource` runner
and run its suite. Results show scenarios with pass/fail status.
Use `<leader>Jo` to toggle the panel. See [java-tests.md](java-tests.md).

Server settings: https://github.com/cucumber/language-server#settings

Update the server with `npm install -g --prefix ~/.local @cucumber/language-server`.
