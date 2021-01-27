# DUP app packaging

- Use Corsica on the server to allow CORS requests (ideally limited to just the DUP-relevant routes).
- Double check that any behavior specific to the DUP screen environment happens inside of an `isDup()` check. This includes:
  - `buildApiPath` in use_api_response.tsx should return a full URL for the API path: prefix `apiPath` string with "https://screens.mbta.com".
  - `App` component in dup.tsx should just return `<ScreenPage screenContainer={ScreenContainer} />`.
  - `imagePath` in util.tsx should return relative paths (no leading `/`).
  - `ScreenPage` component in dup_screen_page.tsx should render `DupScreenPage` rather than `DevelopmentScreenPage`.
- Build the minified JS/CSS with `npm --prefix assets run deploy`.
- Create priv/static/dup-app.html if it doesn’t already exist. Copy paste contents as directed below.
- Copy the following files into the correct location:
  ```sh
  cd priv/static
  cp css/dup.css js/polyfills.js js/dup.js .
  ```
- Create a zip folder containing dup-app.html, dup.css, polyfills.js, and dup.js at the top level; as well as the images directory. You will have a zip folder for each rotation index: dup-app-0.zip, dup-app-1.zip, dup-app-2.zip. For each zip you can either:
  - manually edit dup.js to set a different value for the `ROTATION_INDEX` constant, or
  - edit the `ROTATION_INDEX` constant in rotation_index.tsx, rerun `npm --prefix assets run deploy`, and then copy dup.js to priv/static once again.

Contents of dup-app.html:
```html
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Screens</title>
  <link rel="stylesheet" href="https://use.typekit.net/emd6vhv.css">
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
console.log = function(msg) {
  // first call old logger for console output
  old_logger.call(this, arguments);
  // check what we need to output (object or text) and add it to the html element.
  if (typeof msg == "object") {
      html_logger.innerHTML += "<div>" + (JSON && JSON.stringify ? JSON.stringify(msg) : msg) + "<div>";
  } else {
      html_logger.innerHTML += "<div>" + msg + "<div>";
  }
};
```
