# DUP app packaging

- Double check that any behavior specific to the packaged environment happens inside of an `isOutfront()` condition.
- If you've renamed / removed image assets, you might want to delete the corresponding folder in `/priv/static`. The folder accumulates assets without clearing old ones out, and these will be included in the built bundle!
- **Only if you are packaging for local testing:** To test against your local screens backend instead of production, then replace the value of `data-api-origin` in [`priv/dup-app.html`][dup-app.html] with `http://localhost:4000`.
- Run `scripts/build_dup_client_package.sh`. The packaged client apps will be output at `priv/packaged/dup-app-<rotation>-<version>.zip`.
- To test a created package locally or in Browserstack, you need to add any query param with key `test` to the `index.html`, such as `index.html?test=`.
  - Setting this query param sets up a fake MRAID object that emulates the real one available to the client when running on Outfront screens.
  - You can also set `playerName` and `station` within the URL params to change which screen is emulated.
  - If you are testing multiple iterations locally and don't want to add the URL params with each rebuild of the package, temporarily modify the if statement and/or defaults within [`outfront.tsx`][outfront.tsx]'s `initFakeMRAID` function. Just make sure to remove before sending client packages to Outfront to test.
- When testing is complete, commit the version bump on a branch, push it, and create a PR to mark the deploy.

[dup-app.html]: /priv/dup-app.html
[outfront.tsx]: /assets/src/util/outfront.tsx

## Working with Outfront

Once you've created the client app packages, you'll need to send them to Outfront to test and deploy. Make sure to revert any local changes you've made before generating the packages.

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
