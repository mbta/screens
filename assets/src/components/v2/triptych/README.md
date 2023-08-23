# Triptych app packaging

- Ensure [Corsica](https://hexdocs.pm/corsica/Corsica.html) is used on the server to allow CORS requests (ideally limited to just the triptych-relevant routes). It should already be configured at [this line](/lib/screens_web/controllers/v2/screen_api_controller.ex#L9) in the API controller--if it is, you don't need to do anything for this step.
- Double check that any behavior specific to the triptych screen environment happens inside of an `isTriptych()` or `isOFM()` check. This includes:
  - `buildApiPath` in use_api_response.tsx should return a full URL for the API path: prefix `apiPath` string with "https://screens.mbta.com".
  - `imagePath` in util.tsx should return relative paths (no leading `/`).
- Create priv/static/triptych-app.html if it doesn’t already exist. Copy paste the following contents in:

  ```html
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Screens</title>
      <link rel="stylesheet" href="triptych_v2.css" />
    </head>

    <body>
      <div
        id="app"
        data-last-refresh="2020-09-25T17:23:00Z"
        data-environment-name="screens-prod"
      ></div>
      <script type="text/javascript" src="polyfills.js"></script>
      <script type="text/javascript" src="triptych_v2.js"></script>
    </body>
  </html>
  ```

- Set the version string in assets/src/components/v2/triptych/version.tsx to `current_year.current_month.current_day.1`.
- In assets/webpack.config.js, change `publicPath` in the font config to have value `'fonts/'`.
- **Only if you are packaging for local testing**
  - add the following to the top of assets/src/apps/v2/triptych.tsx, filling in the string values:
    ```ts
    import { __TEST_setFakeMRAID__ } from "Util/outfront";
    __TEST_setFakeMRAID__({
      playerName: "<a player name from priv/triptych_player_to_screen_id.json>",
      station: "<a station name>",
      triptychPane: "<right | middle | left>"
    });
    ```
    This sets up a fake MRAID object that emulates the real one available to the client when running on Outfront screens.
    The MRAID object gives our client info about which screen it's running on.
  - replace the definition of `getOutfrontAbsolutePath` in assets/src/hooks/v2/use_api_response.tsx with `const getOutfrontAbsolutePath = () => isOFM() ? "http://localhost:4000" : "";`.
  - make sure priv/triptych_player_to_screen_id.json mirrors mbta-ctd-config/screens/triptych_player_to_screen_id-prod.json, or at least contains a mapping for the `playerName` that you hardcoded two steps ago.
- `cd` to priv/static and run the following:
  ```sh
  npm --prefix ../../assets run deploy && \
  cp -r css/triptych_v2.css js/polyfills.js js/triptych_v2.js ../triptych_preview.png . && \
  cp ../triptych_template.json ./template.json && \
  zip -r triptych-app.zip triptych_v2.css polyfills.js triptych_v2.js fonts images triptych-app.html template.json triptych_preview.png
  ```
- On completion, the packaged client app will be saved at `priv/static/triptych-app.zip`.
- Commit the version bump on a branch, push it, and create a PR to mark the deploy.

## Debugging

To assist with debugging on the triptych screens, you can paste this at the module scope in triptych.tsx to have console logs
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
dEl.className = "triptych";
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
