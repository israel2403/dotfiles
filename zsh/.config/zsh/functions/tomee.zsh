# JSP and Apache TomEE project helpers.
#
# Usage:
#   mvn_tomee_new my-webapp
#   mvn_tomee_new --group com.acme --java 21 my-webapp
#   mvn_tomee_new --tomee 10.2.0 my-webapp
mvn_tomee_new() {
  local group="${MVN_TOMEE_GROUP:-com.huerta}"
  local java_release="${MVN_TOMEE_JAVA:-17}"
  local tomee_version="${MVN_TOMEE_VERSION:-10.2.0}"
  local artifact=""

  while (( $# > 0 )); do
    case "$1" in
      -g|--group)
        (( $# >= 2 )) || { print -u2 'mvn_tomee_new: --group needs a value'; return 2; }
        group=$2
        shift 2
        ;;
      -j|--java)
        (( $# >= 2 )) || { print -u2 'mvn_tomee_new: --java needs a value'; return 2; }
        java_release=$2
        shift 2
        ;;
      -t|--tomee)
        (( $# >= 2 )) || { print -u2 'mvn_tomee_new: --tomee needs a value'; return 2; }
        tomee_version=$2
        shift 2
        ;;
      -h|--help)
        cat <<'EOF'
mvn_tomee_new -- create a minimal Jakarta JSP application for Apache TomEE.

Usage:
  mvn_tomee_new [options] <artifactId>

Options:
  -g, --group GROUP_ID    Java package and Maven groupId (default: com.huerta)
  -j, --java RELEASE      Java compiler release, 17 or newer (default: 17)
  -t, --tomee VERSION     Apache TomEE version (default: 10.2.0)
  -h, --help              Show this help

Environment defaults:
  MVN_TOMEE_GROUP, MVN_TOMEE_JAVA, MVN_TOMEE_VERSION

After creation:
  mvn clean package tomee:run
  open http://localhost:8080/<artifactId>/hello
EOF
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        print -u2 -- "mvn_tomee_new: unknown option '$1' (try --help)"
        return 2
        ;;
      *)
        [[ -z $artifact ]] || {
          print -u2 -- "mvn_tomee_new: unexpected argument '$1'"
          return 2
        }
        artifact=$1
        shift
        ;;
    esac
  done

  [[ -n $artifact ]] || {
    print -u2 'mvn_tomee_new: missing <artifactId>. Try: mvn_tomee_new --help'
    return 2
  }
  [[ $artifact =~ '^[A-Za-z0-9][A-Za-z0-9._-]*$' ]] || {
    print -u2 'mvn_tomee_new: artifactId must contain only letters, numbers, dots, underscores, or hyphens'
    return 2
  }
  [[ $group =~ '^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$' ]] || {
    print -u2 'mvn_tomee_new: groupId must also be a valid dotted Java package name'
    return 2
  }
  [[ $java_release =~ '^[0-9]+$' ]] && (( java_release >= 17 )) || {
    print -u2 'mvn_tomee_new: TomEE 10 requires Java release 17 or newer'
    return 2
  }
  [[ ! -e $artifact ]] || {
    print -u2 -- "mvn_tomee_new: path already exists: $artifact"
    return 1
  }

  local package_path=${group//.//}
  local java_dir="$artifact/src/main/java/$package_path"
  local web_dir="$artifact/src/main/webapp"

  command mkdir -p -- "$java_dir" "$web_dir/WEB-INF/views" "$web_dir/css" "$web_dir/js" || return

  cat > "$artifact/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>${group}</groupId>
  <artifactId>${artifact}</artifactId>
  <version>1.0.0-SNAPSHOT</version>
  <packaging>war</packaging>

  <properties>
    <maven.compiler.release>${java_release}</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <tomee.version>${tomee_version}</tomee.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>jakarta.platform</groupId>
      <artifactId>jakarta.jakartaee-web-api</artifactId>
      <version>10.0.0</version>
      <scope>provided</scope>
    </dependency>
  </dependencies>

  <build>
    <finalName>${artifact}</finalName>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.14.0</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-war-plugin</artifactId>
        <version>3.4.0</version>
        <configuration>
          <failOnMissingWebXml>false</failOnMissingWebXml>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.tomee.maven</groupId>
        <artifactId>tomee-maven-plugin</artifactId>
        <version>\${tomee.version}</version>
        <configuration>
          <tomeeVersion>\${tomee.version}</tomeeVersion>
          <tomeeClassifier>webprofile</tomeeClassifier>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
EOF

  cat > "$java_dir/HelloServlet.java" <<EOF
package ${group};

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/hello")
public class HelloServlet extends HttpServlet {
  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    request.setAttribute("message", "Hello from Jakarta Servlet on Apache TomEE!");
    request.getRequestDispatcher("/WEB-INF/views/hello.jsp").forward(request, response);
  }
}
EOF

  cat > "$web_dir/WEB-INF/views/hello.jsp" <<'EOF'
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>TomEE JSP application</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app.css" />
  </head>
  <body>
    <main>
      <h1>${message}</h1>
      <button id="hello-button" type="button">Test JavaScript</button>
      <p id="result" aria-live="polite"></p>
    </main>
    <script src="${pageContext.request.contextPath}/js/app.js"></script>
  </body>
</html>
EOF

  cat > "$web_dir/css/app.css" <<'EOF'
:root {
  color-scheme: light dark;
  font-family: system-ui, sans-serif;
}

body {
  margin: 0;
  min-height: 100vh;
  display: grid;
  place-items: center;
}

main {
  max-width: 42rem;
  padding: 2rem;
  text-align: center;
}
EOF

  cat > "$web_dir/js/app.js" <<'EOF'
document.querySelector("#hello-button").addEventListener("click", () => {
  document.querySelector("#result").textContent = "JavaScript is working.";
});
EOF

  print -r -- '/target/' > "$artifact/.gitignore"

  cd -- "$artifact" || return
  print -r -- "Created Jakarta JSP/TomEE project: $PWD"
  print -r -- "Run:  mvn clean package tomee:run"
  print -r -- "Open: http://localhost:8080/${artifact}/hello"
}
