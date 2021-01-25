# DUP app packaging

- Use Corsica on the server to allow CORS requests (ideally limited to just the DUP-relevant routes).
- Double check that any behavior specific to the DUP screen environment happens inside of an `isDup()` check. This includes:
  - `buildApiPath` in use_api_response.tsx should return a full URL for the API path: prefix `apiPath` string with "https://screens.mbta.com".
  - `App` component in dup.tsx should just return `<ScreenPage screenContainer={ScreenContainer} />`.
  - `imagePath` in util.tsx should return relative paths (no leading `/`).
  - `ScreenPage` component in dup_screen_page.tsx should call `useOutfrontStation` to get station tag info.
- Start the local server normally with `iex -S mix phx.server`, let it compile the JS/CSS.
- Create priv/static/dup-app.html if it doesn’t already exist. Copy paste contents as directed below.
- Create a zip folder containing dup-app.html at the top level, as well as the images directory. You will have a zip folder for each rotation index: dup-app-0.zip, dup-app-1.zip, dup-app-2.zip. For each zip you can either:
  - manually edit dup-app.html to pass a different rotation index prop to the `ScreenContainer` component, or
  - edit the `ROTATION_INDEX` constant in rotation_index.tsx, let the JS recompile, and then copy-paste it all into dup-app.html.

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
