# Triptych app packaging

- Ensure [Corsica](https://hexdocs.pm/corsica/Corsica.html) is used on the server to allow CORS requests (ideally limited to just the triptych-relevant routes). It should already be configured at [this line](/lib/screens_web/controllers/v2/screen_api_controller.ex#L9) in the API controller--if it is, you don't need to do anything for this step.
- Double check that any behavior specific to the triptych screen environment happens inside of an `isOFM()` check. This includes:
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
  - replace `const playerName = useOutfrontPlayerName();` in assets/src/apps/v2/triptych.tsx with `const playerName = "BKB-TRI-001";` (or any other player name from one of the triptych screen IDs (`TRI-${playerName}`)). This data is provided by Outfront's "wrapper" app that runs on the real triptych screens, but we need to set it ourselves during testing. Think of it as a sort of frontend environment variable.
  - replace `apiPath = "https://screens.mbta.com...";` in assets/src/hooks/v2/use_api_response.tsx with `apiPath = "http://localhost:4000...";`.
- `cd` to priv/static and run the following:
  ```sh
  for PANE in left middle right; do
    echo "export const TRIPTYCH_PANE = \"${PANE}\";" > ../../assets/src/components/v2/triptych/pane.tsx
    npm --prefix ../../assets run deploy
    cp -r css/triptych_v2.css js/polyfills.js js/triptych_v2.js ../triptych_preview.png .
    cp ../triptych_template.json ./template.json
    sed -i "" -E "s/TRIPTYCH APP [[:alpha:]]+/TRIPTYCH APP $(echo $PANE | tr 'a-z' 'A-Z')/" template.json
    zip -r triptych-app-${PANE}.zip triptych_v2.css polyfills.js triptych_v2.js fonts images triptych-app.html template.json triptych_preview.png
  done
  ```
- On completion, the packaged client apps will be saved at `priv/static/triptych-app-(left|middle|right).zip`.
- Commit the version bump on a branch, push it, and create a PR to mark the deploy.

## Debugging

To assist with debugging on the triptych screens, you can paste this at the module scope in triptych.tsx to have console logs
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
