<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>TomEE JSP demo</title>
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
