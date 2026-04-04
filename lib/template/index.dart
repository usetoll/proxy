final index = '''
  <html lang="">
  
  <head>
  <script>
setTimeout(() => {
    const nonce = '{{{nonce}}}';
    const url = '{{{url}}}';
    const params = new URLSearchParams(window.location.search);
      params.set("pow", nonce);
      params.set("url", url);
      window.location.search = params.toString();
}, 2000)
  </script>
  </head>
  
  <body>
  <p>Computing...</p>
  </body>
  </html>
''';