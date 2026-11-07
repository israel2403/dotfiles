# Java and Spring test results

- `<leader>JT` / `:JavaTestFile`: save and run the current Java test class.
  Classes named `IT*`, `*IT`, or `*ITCase` use Maven Failsafe; other test
  classes use Surefire. Uses the nearest pom.xml and executable mvnw.
- In a `.feature` under `src/test/resources`, the same key finds Java Cucumber
  `@Suite` classes whose `@SelectClasspathResource("…")` contains that feature.
  If several match, choose one. **Runs the matching suite**, including its other
  features. It preserves the suite's glue, Spring context, tags and settings.
- `<leader>Jo` / `:JavaTestResults`: show/hide results. Running tests opens the
  panel below the editor and keeps focus in the source file.
- In results: `Enter` collapses a suite or opens test failure details; `o`
  switches between results and build logs; `r` reruns; `s` stops Maven;
  `q`, `Esc`, or `Ctrl-/` hides the panel and restores the source window.
  `<leader>Jo` works from either the panel or the source file.

Results show the changed Surefire/Failsafe XML reports for this run only,
including Cucumber scenarios reported by JUnit. Build errors without test reports
remain visible in the log view. Results appear when Maven finishes; logs update
while it runs. The unlisted scratch buffer does not add a bufferline tab.
Requires Python 3 for standard-library XML parsing. No additional Neovim plugin.
Integration tests use `test-compile failsafe:integration-test failsafe:verify`,
so they do not invoke the full `verify` lifecycle or unrelated coverage gates.
Projects needing Maven-managed pre/post-integration-test services must run their
normal lifecycle separately. Your Testcontainers-based Spring tests manage their
own containers.
