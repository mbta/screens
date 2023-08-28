# DUP app packaging v2

- Ensure [Corsica](https://hexdocs.pm/corsica/Corsica.html) is used on the server to allow CORS requests (ideally limited to just the DUP-relevant routes). It should already be configured at [this line](/lib/screens_web/controllers/v2/screen_api_controller.ex#L9) in the API controller--if it is, you don't need to do anything for this step.
- Double check that any behavior specific to the DUP screen environment happens inside of an `isDup()` or `isOFM()` check. This includes:
  - `buildApiPath` in use_api_response.tsx should return a full URL for the API path: prefix `apiPath` string with "https://screens.mbta.com".
  - `imagePath` in util.tsx should return relative paths (no leading `/`).
- Create priv/static/dup-app.html if it doesn’t already exist. Copy paste the following contents in:

  ```html
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Screens</title>
      <link rel="stylesheet" href="dup_v2.css" />
    </head>

    <body>
      <div
        id="app"
        data-last-refresh="2020-09-25T17:23:00Z"
        data-environment-name="screens-prod"
      ></div>
      <script type="text/javascript" src="polyfills.js"></script>
      <script type="text/javascript" src="dup_v2.js"></script>
    </body>
  </html>
  ```

- Set the version string in assets/src/components/v2/dup/version.tsx to `current_year.current_month.current_day.1`.
- In assets/webpack.config.js, change `publicPath` in the font config to have value `'fonts/'`.
- **Only if you are packaging for local testing**
  - add the following to the top of assets/src/apps/v2/dup.tsx, filling in the string values:
    ```ts
    import { __TEST_setFakeMRAID__ } from "Util/outfront";
    __TEST_setFakeMRAID__({
      playerName: "<a DUP player name, e.g. BKB-DUP-002. For others, look in priv/local.json for IDs of the pattern 'DUP-${playerName}'>",
      station: "<a station name>"
    });
    ```
    This sets up a fake MRAID object that emulates the real one available to the client when running on Outfront screens.
    The MRAID object gives our client info about which screen it's running on.
  - replace the definition of `getOutfrontAbsolutePath` in assets/src/hooks/v2/use_api_response.tsx with `const getOutfrontAbsolutePath = () => isOFM() ? "http://localhost:4000" : "";`.
- `cd` to priv/static and run the following:
  ```sh
  for ROTATION_INDEX in {0..2}; do
    echo "export const ROTATION_INDEX = ${ROTATION_INDEX};" > ../../assets/src/components/v2/dup/rotation_index.tsx && \
    npm --prefix ../../assets run deploy && \
    cp -r css/dup_v2.css js/polyfills.js js/dup_v2.js ../dup_preview.png . && \
    cp ../dup_template.json ./template.json && \
    sed -i "" "s/DUP APP ./DUP APP ${ROTATION_INDEX}/" template.json && \
    zip -r dup-app-${ROTATION_INDEX}.zip dup_v2.css polyfills.js dup_v2.js fonts images dup-app.html template.json dup_preview.png
  done
  ```
- On completion, the packaged client apps will be saved at `priv/static/dup-app-(0|1|2).zip`.
- Commit the version bump on a branch, push it, and create a PR to mark the deploy.

## Debugging

To assist with debugging on the DUP screens, you can paste this at the module scope in dup.tsx to have console logs
show up on the screen:

```js
const Counter = (() => {
  let n = 0;

  return {
    next() {
      let cur = n;
      n = (n + 1) % 100;
      return `${cur.toString().padStart(2, "0")}`;
    }
  };
})();

const dEl = document.createElement("div");
dEl.id = "debug";
dEl.className = "dup";
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
  html_logger.innerHTML = `<div class="line">${Counter.next()} ${text} </div>${html_logger.innerHTML}`;
};
```
