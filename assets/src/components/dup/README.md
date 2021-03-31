# DUP app packaging

- Use Corsica on the server to allow CORS requests (ideally limited to just the DUP-relevant routes).
- Double check that any behavior specific to the DUP screen environment happens inside of an `isDup()` check. This includes:
  - `buildApiPath` in use_api_response.tsx should return a full URL for the API path: prefix `apiPath` string with "https://screens.mbta.com".
  - `App` component in dup.tsx should just return `<ScreenPage screenContainer={ScreenContainer} />`.
  - `imagePath` in util.tsx should return relative paths (no leading `/`).
  - `ScreenPage` component in dup_screen_page.tsx should render `DupScreenPage` rather than `DevelopmentScreenPage`.
- Create priv/static/dup-app.html if it doesn’t already exist. Copy paste contents as directed below.
- Set the version string in assets/src/components/dup/version.tsx to `current_year.current_month.current_day.1`.
- In assets/webpack.config.js, change `publicPath` in the font config to have value `'fonts/'`.
- `cd` to priv/static and run the following:
  ```sh
  for ROTATION_INDEX in {0..2}; do
    echo "export const ROTATION_INDEX = ${ROTATION_INDEX};" > ../../assets/src/components/dup/rotation_index.tsx
    npm --prefix ../../assets run deploy
    cp -r css/dup.css js/polyfills.js js/dup.js ../dup_font_face.css ../fonts .
    zip -r dup-app-${ROTATION_INDEX}.zip dup.css polyfills.js dup.js dup_font_face.css fonts images dup-app.html
  done
  ```
- Commit the version bump on a branch, push it, and create a PR to mark the deploy.

Contents of dup-app.html:
```html
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Screens</title>
  <link rel="stylesheet" href="dup_font_face.css">
  <link rel="stylesheet" href="dup.css">
</head>

<body>
  <div id="app" data-last-refresh="2020-09-25T17:23:00Z" data-environment-name="screens-prod"></div>
  <script type="text/javascript" src="polyfills.js"></script>
  <script type="text/javascript" src="dup.js"></script>
</body>

</html>
```

## Debugging

To assist with debugging on the DUP screens, you can paste this at the module scope in dup.tsx to have console logs
show up on the screen:
```js
const dEl = document.createElement("div");
dEl.id = "debug";
document.body.appendChild(dEl);
// save the original console.log function
const old_logger = console.log;
// grab html element for adding console.log output
const html_logger = document.getElementById("debug");
// replace console.log function with our own function
console.log = function (...msgs) {
  // first call old logger for console output
  old_logger.call(this, arguments);

  // convert object args to strings and join them together
  const text = msgs
    .map((msg) => {
      if (typeof msg == "object") {
        return JSON && JSON.stringify ? JSON.stringify(msg) : msg;
      } else {
        return msg;
      }
    })
    .join(" ");

  // add the log to the html element.
  html_logger.innerHTML += "<div>" + text + "<div>";
};
```
