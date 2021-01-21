# DUP app packaging

- Use Corsica on the server to allow CORS requests (ideally limited to just the DUP-relevant routes).
- Edit use_api_response.tsx to use an absolute URL for the API path: prefix `apiPath` string with "https://screens.mbta.com".
- Edit dup.tsx, App component to return simply the following:
  ```jsx
  return (
    <ScreenPage screenContainer={ScreenContainer} />
  );
  ```
- Edit `imagePath` function in `util.tsx` to omit the leading `/`, making all paths relative. (Also double-check that there aren't any stray \<img\> tags across the codebase that don't use this function for their `src`! There should be no instances of "/images/" in the frontend code besides in `imagePath`).
- Start the local server normally with `iex -S mix phx.server`, let it compile the JS/CSS.
- Create priv/static/dup-app.html if it doesn’t already exist. Copy paste contents as directed below.
- Create a zip folder containing dup-app.html at the top level, as well as the images directory. You will have a zip folder for each rotation index: dup-app-0.zip, dup-app-1.zip, dup-app-2.zip. For each zip you will need to manually edit dup-app.html to pass a different rotation index prop to the `ScreenContainer` component.

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
    <script type="text/javascript">
      // paste contents of /priv/static/js/polyfills.js
      // (remove sourcemap comment at end to prevent console warnings)
    </script>
    <script type="text/javascript">
      // paste contents of /priv/static/js/dup.js
      // (remove sourcemap comment at end to prevent console warnings)
    </script>
  </body>
</html>
```
