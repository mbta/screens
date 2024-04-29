//////////////////// On-screen console logs
const Counter = (() => {
  let n = 0;

  return {
    next() {
      let cur = n;
      n = (n + 1) % 100;
      if (cur < 10) {
        return "0".concat(cur.toString());
      } else {
        return cur.toString();
      }
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
console.log = function () {
  // first call old logger for console output
  old_logger.call(this, arguments);

  // convert object args to strings and join them together
  const text = Array.from(arguments)
    .map((msg) => {
      if (typeof msg == "object") {
        return JSON && JSON.stringify ? JSON.stringify(msg) : msg;
      } else {
        return msg;
      }
    })
    .join(" ");

  // add the log to the html element.
  html_logger.innerHTML = "<div class=\"line\">"
    .concat(Counter.next())
    .concat(" ")
    .concat(text)
    .concat(" </div>")
    .concat(html_logger.innerHTML);
};
console.log("on-screen console.log set up");
/////////////////////////////////////

/////////////////// set up fake MRAID
(() => {
  // 👇 Adjust these values to change what player the client thinks it's running on.
  const OPTIONS = { playerName: "TESTING-BKB-DS-003", triptychPane: "right", station: "Back Bay" };
  // 👆

  const BASE_MRAID = {
    // Stubbed methods/fields for foreground detection logic
    EVENTS: { ONSCREEN: "fakeOnscreenEvent" },
    requestInit() {
      return "fakeLayoutID";
    },
    addEventListener(eventID, callback, layoutID) {
      if (eventID == "fakeOnscreenEvent" && layoutID == "fakeLayoutID") {
        console.log(
          "FakeMRAID: Setting fake ONSCREEN event to fire in 3 seconds"
        );

        setTimeout(() => {
          console.log("FakeMRAID: Firing fake ONSCREEN event");
          callback();
        }, 2000);
      } else {
        throw new Error(
          "FakeMRAID: Stubbed addEventListener method expected eventID of 'fakeOnscreenEvent' and layoutID of 'fakeLayoutID'"
        );
      }
    },
  };

  const { playerName, station, triptychPane } = OPTIONS;

  const triptychPaneToArrayConfiguration = (pane) => {
    return `Triple_${pane[0].toUpperCase().concat(pane.slice(1))}`;
  };

  let tags = [{ name: "Station", value: [station] }];
  if (triptychPane) {
    tags.push({
      name: "Array_configuration",
      value: [triptychPaneToArrayConfiguration(triptychPane)],
    });
  }
  const tagsJSON = JSON.stringify({ tags });

  const deviceInfoJSON = JSON.stringify({ deviceName: playerName });

  const mraid = {
    ...BASE_MRAID,
    getTags() {
      return tagsJSON;
    },
    getDeviceInfo() {
      return deviceInfoJSON;
    },
  };

  console.log(`Setting fake MRAID object for testing purposes: ${JSON.stringify(OPTIONS)}`);

  // Since `window.parent.parent.parent...` returns itself if the window does not have a parent, we can just set the mraid object
  // on the current window, and the code that reads `window.parent.parent.mraid` will still access it correctly.
  window.mraid = mraid;
})();
/////////////////////////////////////
