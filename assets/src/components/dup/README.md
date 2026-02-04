# DUP app packaging

- Ensure [Corsica](https://hexdocs.pm/corsica/Corsica.html) is used on the server to allow CORS requests (ideally limited to just the DUP-relevant routes). It should already be configured at [this line](/lib/screens_web/controllers/v2/screen_api_controller.ex#L9) in the API controller--if it is, you don't need to do anything for this step.
- Double check that any behavior specific to the DUP screen environment happens inside of an `isDup()` check. This includes:

  - `buildApiPath` in use_api_response.tsx should return a full URL for the API path: prefix `apiPath` string with "https://screens.mbta.com".
  - `imagePath` in util.tsx should return relative paths (no leading `/`).

- Set the version string in assets/src/components/dup/version.tsx to `current_year.current_month.current_day.1`.
- If you've renamed / removed image assets, you might want to delete the corresponding folder in `/priv/static`. The folder accumulates assets without clearing old ones out, and these will be included in the built bundle!
- **Only if you are packaging for local testing:** To test against your local screens backend instead of production, then replace the definition of `OUTFRONT_BASE_URI` in `assets/src/hooks/use_api_response.tsx` with `"http://localhost:4000"`.
- `cd` to priv/static and run the following shell script: `sh build_dup_client_package.sh`
- On completion, the packaged client apps will be saved at `priv/static/dup-app-(0|1|2).zip`.
- To test the created package locally or in Browserstack, you need to add any query param with key `test` to the `index.html`, such as `index.html?test=`.
  - Setting this query param sets up a fake MRAID object that emulates the real one available to the client when running on Outfront screens.
  - You can also set `playerName` and `station` within the URL params to change which screen is emulated.
  - If you are testing multiple iterations locally and don't want to add the URL params with each rebuild of the package, temporarily modify the if statment and/or defaults within `outfront.tsx`'s `initFakeMRAID` function. Just make sure to remove before sending client packages to Outfront to test.
- When testing is complete, commit the version bump on a branch, push it, and create a PR to mark the deploy.

## Working with Outfront

Once you've created the client app packages, you'll need to send them to Outfront to test and deploy. Make sure to remove any changes that you made to `outfront.tsx` and `use_api_response.tsx` for local testing before generating packages for Outfront.

For detailed instructions on this process, go to [this Notion doc](https://www.notion.so/mbta-downtown-crossing/Deploying-DUP-Package-Updates-120f5d8d11ea805fa219f214c1633293).

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
    },
  };
})();

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
  if (html_logger) {
    html_logger.innerHTML = `<div class="line">${Counter.next()} ${text} </div>${html_logger.innerHTML}`;
  }
};
```
