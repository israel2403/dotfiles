# Java and Maven helpers.
_run_java_free_port() {
  command python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
}

run_java() {
  if [ ! -f pom.xml ]; then
    echo "run_java: no pom.xml found in the current directory" >&2
    return 1
  fi

  # Jakarta web applications configured with the TomEE Maven plugin are WAR
  # projects without a conventional main method. Package and launch them in
  # the embedded TomEE server instead.
  if grep -qE '<artifactId>tomee-maven-plugin</artifactId>' pom.xml; then
    local port shutdown_port
    port=$(_run_java_free_port) || {
      echo "run_java: could not find a free port" >&2
      return 1
    }
    shutdown_port=$(_run_java_free_port) || {
      echo "run_java: could not find a free shutdown port" >&2
      return 1
    }

    echo "run_java: TomEE will use http://localhost:$port"
    mvn clean package tomee:run \
      -Dtomee-plugin.http="$port" \
      -Dtomee-plugin.shutdown="$shutdown_port" \
      "$@"
    return $?
  fi

  # Spring Boot projects provide their own run goal and may not have a
  # conventional main class under src/main/java.
  if grep -qE '<artifactId>spring-boot-(starter-parent|maven-plugin)</artifactId>' pom.xml; then
    local port
    port=$(_run_java_free_port) || {
      echo "run_java: could not find a free port" >&2
      return 1
    }

    echo "run_java: Spring Boot will use http://localhost:$port"
    mvn spring-boot:run "-Dspring-boot.run.jvmArguments=-Dserver.port=$port" "$@"
    return $?
  fi

  # Plain Maven projects need a main class for exec:java. JAVA_MAIN_CLASS can
  # be used when a project has multiple entry points or a nonstandard layout.
  local main_class="${JAVA_MAIN_CLASS:-}"
  if [ -z "$main_class" ]; then
    local -a main_files
    main_files=("${(@f)$(grep -rlE \
      'public[[:space:]]+static[[:space:]]+void[[:space:]]+main[[:space:]]*\(' \
      src/main/java --include='*.java' 2>/dev/null)}")

    if [ ${#main_files[@]} -eq 0 ]; then
      echo "run_java: no main method found under src/main/java" >&2
      echo "          set JAVA_MAIN_CLASS to the fully qualified class name" >&2
      return 1
    fi
    if [ ${#main_files[@]} -gt 1 ]; then
      echo "run_java: multiple main classes found:" >&2
      printf '  %s\n' "${main_files[@]}" >&2
      echo "          select one with JAVA_MAIN_CLASS=com.example.Main run_java" >&2
      return 1
    fi

    local package_name class_name
    package_name=$(sed -nE \
      's/^[[:space:]]*package[[:space:]]+([^;]+);.*/\1/p' \
      "$main_files[1]" | head -1)
    class_name=${main_files[1]:t:r}
    main_class="${package_name:+${package_name}.}${class_name}"
  fi

  mvn compile org.codehaus.mojo:exec-maven-plugin:java \
    -Dexec.mainClass="$main_class" "$@"
}
test_java() { mvn test "$@"; }
mvnc()      { mvn clean install -DskipTests "$@"; }

# Resolve a Java version request (major like '21', SDKMAN id like '21.0.10-tem',
# or empty) into the best matching SDKMAN identifier installed on this box.
# Echoes the identifier on success; echoes the original argument on miss so the
# caller can still write something sensible into .sdkmanrc.
_mvn_new_resolve_sdkman_java() {
  local want=$1
  local sdk_dir="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java"
  [ -d "$sdk_dir" ] || { printf '%s\n' "$want"; return 1; }

  # Specific SDKMAN id passed and installed.
  if [ -n "$want" ] && [ -d "$sdk_dir/$want" ]; then
    printf '%s\n' "$want"
    return 0
  fi

  # Major-only -> newest installed entry whose major matches.
  if [ -n "$want" ] && printf '%s' "$want" | grep -qE '^[0-9]+$'; then
    local cand
    cand=$(ls -1 "$sdk_dir" 2>/dev/null \
      | grep -E "^${want}([.-]|$)" \
      | sort -V \
      | tail -1)
    if [ -n "$cand" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
    printf '%s\n' "$want"
    return 2  # major requested but no installed match
  fi

  # No version requested -> use the current SDKMAN java if any.
  if [ -L "$sdk_dir/current" ]; then
    basename "$(readlink "$sdk_dir/current")"
    return 0
  fi
  return 1
}

# mvn_new -- scaffold a clean Maven quickstart project pinned to a chosen
# Java release. Java version is flexible:
#   * --java N            explicit major (21, 25, …) or SDKMAN id (21.0.10-tem)
#   * \$MVN_NEW_JAVA       env var fallback
#   * SDKMAN current java if neither set
#   * 21 as final fallback
# Group id is configurable the same way (--group / \$MVN_NEW_GROUP, default
# com.huerta).
#
# Project changes vs. the upstream archetype:
#   * Pins maven-archetype-quickstart:1.5 (the first version that supports a
#     modern Java release out of the box).
#   * Rewrites pom.xml to set maven.compiler.source/target/release to the
#     selected major (release is the canonical Java >=9 property).
#   * Adds Spotless configured with google-java-format using Google style.
#   * Runs Spotless once so the archetype-generated sources start compliant.
#   * Writes a .sdkmanrc so 'cd <project>' in an SDKMAN-aware shell switches
#     to the chosen JDK automatically.
#
# Usage:
#   mvn_new my-app                       # current/default Java
#   mvn_new --java 21 my-app             # pin to Java 21
#   mvn_new --java 25 --group com.acme my-app
#   MVN_NEW_JAVA=25 mvn_new my-app       # via env var
mvn_new() {
  local java_version="${MVN_NEW_JAVA:-}"
  local group="${MVN_NEW_GROUP:-com.huerta}"
  local artifact=""
  local archetype_version="1.5"

  while [ $# -gt 0 ]; do
    case "$1" in
      -j|--java)
        java_version=$2
        shift 2 || return 2
        ;;
      -g|--group)
        group=$2
        shift 2 || return 2
        ;;
      --archetype-version)
        archetype_version=$2
        shift 2 || return 2
        ;;
      -h|--help)
        cat <<'EOF'
mvn_new -- scaffold a Maven quickstart project pinned to a chosen Java release.

Usage:
  mvn_new [-j|--java VERSION] [-g|--group GROUP_ID] [--archetype-version VER] <artifactId>

Options:
  -j, --java VERSION         major (e.g. 21, 25) or full SDKMAN id (e.g. 21.0.10-tem).
                             Defaults to \$MVN_NEW_JAVA, then SDKMAN current java, then 21.
  -g, --group GROUP_ID       Maven groupId. Defaults to \$MVN_NEW_GROUP, then com.huerta.
      --archetype-version V  Override maven-archetype-quickstart version (default 1.5).

Examples:
  mvn_new my-app
  mvn_new --java 21 --group com.acme certification-prep
  MVN_NEW_JAVA=25 mvn_new future-app
EOF
        return 0
        ;;
      --)
        shift; break
        ;;
      -*)
        echo "mvn_new: unknown option '$1' (try --help)" >&2
        return 2
        ;;
      *)
        if [ -z "$artifact" ]; then
          artifact=$1
          shift
        else
          echo "mvn_new: unexpected argument '$1'" >&2
          return 2
        fi
        ;;
    esac
  done

  if [ -z "$artifact" ]; then
    echo "mvn_new: missing <artifactId>. Try: mvn_new --help" >&2
    return 1
  fi

  # Resolve SDKMAN id (may rewrite a bare major like '21' to e.g. '21.0.10-tem').
  local sdk_id
  sdk_id=$(_mvn_new_resolve_sdkman_java "$java_version")
  local resolve_rc=$?

  # If the resolver couldn't find anything and the user didn't supply a value,
  # default to Java 21.
  if [ -z "$java_version" ] && [ -z "$sdk_id" ]; then
    sdk_id="21"
    java_version="21"
  fi
  [ -z "$java_version" ] && java_version="$sdk_id"

  # Major number used for maven.compiler.{source,target,release}.
  local java_major
  java_major=$(printf '%s' "$java_version" | sed -E 's/^([0-9]+).*/\1/')
  if ! printf '%s' "$java_major" | grep -qE '^[0-9]+$'; then
    echo "mvn_new: could not derive a numeric Java major from '$java_version'" >&2
    return 2
  fi

  echo ">>> mvn_new: artifact=$artifact  group=$group  java=$java_major  sdkman=$sdk_id  archetype=$archetype_version"
  if [ "$resolve_rc" = "2" ]; then
    echo "    note: SDKMAN has no installed Java with major '$java_major'."
    echo "          .sdkmanrc will be written with '$sdk_id'; run 'sdk install java $sdk_id' to populate."
  fi

  mvn archetype:generate \
    -DgroupId="$group" \
    -DartifactId="$artifact" \
    -DarchetypeGroupId=org.apache.maven.archetypes \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DarchetypeVersion="$archetype_version" \
    -DjavaCompilerVersion="$java_major" \
    -DinteractiveMode=false || return $?

  cd "$artifact" || return

  # Standard layout (the archetype already creates most of this).
  mkdir -p src/main/java src/main/resources src/test/java

  # Rewrite pom.xml to pin source/target/release to the chosen Java major.
  # release is the canonical property for Java 9+ and supersedes source/target.
  if [ -f pom.xml ]; then
    sed -i \
      -e "s|<maven\.compiler\.source>[^<]*</maven\.compiler\.source>|<maven.compiler.source>${java_major}</maven.compiler.source>|" \
      -e "s|<maven\.compiler\.target>[^<]*</maven\.compiler\.target>|<maven.compiler.target>${java_major}</maven.compiler.target>|" \
      pom.xml
    if ! grep -q '<maven\.compiler\.release>' pom.xml; then
      sed -i \
        "s|<maven\.compiler\.target>${java_major}</maven\.compiler\.target>|<maven.compiler.target>${java_major}</maven.compiler.target>\n    <maven.compiler.release>${java_major}</maven.compiler.release>|" \
        pom.xml
    fi
    if ! grep -q '<artifactId>spotless-maven-plugin</artifactId>' pom.xml; then
      local spotless_plugin
      spotless_plugin='      <plugin>
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
      </plugin>'

      if perl -0ne '$found = 1 if m|<build>\s*<plugins>|; END { exit($found ? 0 : 1) }' pom.xml; then
        perl -0pi -e "s|(<build>\\s*<plugins>\\n)|\${1}${spotless_plugin}\n|s" pom.xml
      elif grep -q '<build>' pom.xml; then
        perl -0pi -e "s|(<build>\\n)(\\s*<pluginManagement>)|\${1}    <plugins>\n${spotless_plugin}\n    </plugins>\n\n\${2}|s; s|(<build>\\n)(?!\\s*<plugins>)|\${1}    <plugins>\n${spotless_plugin}\n    </plugins>\n|s" pom.xml
      else
        perl -0pi -e "s|</project>|  <build>\n    <plugins>\n${spotless_plugin}\n    </plugins>\n  </build>\n</project>|" pom.xml
      fi
    fi
  fi

  # .sdkmanrc -- 'cd' into the project auto-switches the JDK if you've
  # enabled sdkman_auto_env in ~/.sdkman/etc/config.
  printf 'java=%s\n' "$sdk_id" > .sdkmanrc

  mvn -q spotless:apply || return $?

  echo "✅ Clean Maven project ready  (Java release=$java_major, .sdkmanrc=java=$sdk_id)"
}
