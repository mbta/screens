# DUP app packaging

- Use Corsica on the server to allow CORS requests (ideally limited to just the DUP-relevant routes)
- Edit use_api_response.tsx to use an absolute URL for the API path: prefix `apiPath` string with "https://screens-dev-green.mbtace.com"
- For each DUP screen ID, edit dup.tsx, App component to return simply the following:
  ```jsx
  return (
    <ScreenContainer id={$ID_AS_STRING} />
  );
  ```
- For all \<img\> tags, remove the leading “/“ in the src attribute to make the path relative to the html file
- Start the local server normally with `iex -S mix phx.server`, let it compile the JS/CSS
- Create priv/static/dup-app.html if it doesn’t already exist. Copy paste contents as directed below
- Create a zip folder containing dup-app.html at the top level, as well as the images directory. You will have a zip folder for each screen, e.g. dup-app-401.zip, dup-app-402.zip, ...

Contents of dup-app.html:
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Screens</title>
    <link rel="stylesheet" href="https://use.typekit.net/emd6vhv.css">
    <style>
      /* paste contents of /priv/static/css/dup.css */
      /* (remove sourcemap comment at end to prevent console warnings) */
    </style>
  </head>
  <body>
    <div id="app" data-last-refresh="2020-09-25T17:23:00Z" data-environment-name="screens-prod"></div>
    <script type=“text/javascript">
      // paste contents of /priv/static/js/polyfills.js
      // (remove sourcemap comment at end to prevent console warnings)
    </script>
    <script type=“text/javascript”>
      // paste contents of /priv/static/js/dup.js
      // (remove sourcemap comment at end to prevent console warnings)
    </script>
  </body>
</html>
```