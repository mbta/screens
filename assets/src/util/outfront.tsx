import { ROTATION_INDEX } from "Components/v2/dup/rotation_index";
import { getDatasetValue } from "Util/dataset";

/**
 * Returns true if this client is running on a DUP screen.
 *
 * Use this for DUP-specific logic.
 */
export const isDup = () => /^file:.*dup-app.*/.test(location.href);

type RotationIndex = "0" | "1" | "2";
const isRotationIndex = (value: any): value is RotationIndex => {
  return value === "0" || value === "1" || value === "2";
};

export const getRotationIndex = (): RotationIndex | null => {
  const rotationIndex = isDup()
    ? ROTATION_INDEX.toString()
    : getDatasetValue("rotationIndex");

  return isRotationIndex(rotationIndex) ? rotationIndex : null;
};

/**
 * Gets Outfront's unique name/ID for the media player we're running on.
 *
 * Returns null if we fail to determine the player name for any reason.
 */
export const getPlayerName = (): string | null => {
  let playerName = null;

  const mraid = getMRAID();
  if (mraid) {
    try {
      const deviceInfoJSON = mraid.getDeviceInfo();
      const deviceInfo = JSON.parse(deviceInfoJSON);
      playerName = deviceInfo.deviceName;
    } catch {}
  }

  return playerName;
};

/**
 * Gets name of the station (e.g. "Back Bay") from the `Station` tag.
 *
 * Returns null if we fail to determine the station name for any reason.
 */
export const getStationName = (): string | null => {
  const tags = getTags();

  if (tags != null) {
    return tags.find(({ name }) => name === "Station")?.value?.[0] ?? null;
  }

  return null;
};

const getTags = (): OFMTag[] | null => {
  let tags: OFMTag[] | null = null;

  const mraid = getMRAID();
  if (mraid) {
    try {
      tags = JSON.parse(mraid.getTags()).tags as OFMTag[];
    } catch {}
  }

  return tags;
};

interface OFMWindow extends Window {
  mraid?: MRAID;
}

interface MRAID {
  getTags(): string;
  getDeviceInfo(): string;

  // The below fields/methods are used by logic that runs when the app is foregrounded
  requestInit(): LayoutID;
  addEventListener(
    eventID: EventID,
    callback: () => void,
    layoutID: LayoutID,
  ): void;
  EVENTS: { ONSCREEN: EventID };
}

type LayoutID = any;
type EventID = any;

interface OFMTag {
  name: string;
  value: [any];
}

export const getMRAID = (): MRAID | false => {
  if (!isDup()) return false;
  return (parent?.parent as OFMWindow)?.mraid ?? false;
};

/**
 * For use in test DUP packages only! Sets a fake MRAID object on `window` so
 * we can test OFM client packages as if they are running on real OFM screens.
 * @knipignore
 */
export const __TEST_setFakeMRAID__ = (options: {
  playerName: string;
  station: string;
}) => {
  const { playerName, station } = options;

  const tagsJSON = JSON.stringify({
    tags: [{ name: "Station", value: [station] }],
  });

  const deviceInfoJSON = JSON.stringify({ deviceName: playerName });

  const mraid: MRAID = {
    ...BASE_MRAID,
    getTags() {
      return tagsJSON;
    },
    getDeviceInfo() {
      return deviceInfoJSON;
    },
  };

  // Be noisy about it so that we don't accidentally ship a package that calls this function.
  alert(
    `Setting fake MRAID object for testing purposes: ${JSON.stringify(options)}`,
  );

  // Since `window.parent.parent.parent...` returns itself if the window does not have a parent, we can just set the mraid object
  // on the current window, and the code that reads `window.parent.parent.mraid` will still access it correctly.
  (window as OFMWindow).mraid = mraid;
};

const BASE_MRAID: Pick<MRAID, "EVENTS" | "requestInit" | "addEventListener"> = {
  // Stubbed methods/fields for foreground detection logic
  EVENTS: { ONSCREEN: "fakeOnscreenEvent" },
  requestInit() {
    return "fakeLayoutID";
  },
  addEventListener(eventID, callback, layoutID) {
    if (eventID == "fakeOnscreenEvent" && layoutID == "fakeLayoutID") {
      console.log(
        "FakeMRAID: Setting fake ONSCREEN event to fire in 3 seconds",
      );

      setTimeout(() => {
        console.log("FakeMRAID: Firing fake ONSCREEN event");
        callback();
      }, 2000);
    } else {
      throw new Error(
        "FakeMRAID: Stubbed addEventListener method expected eventID of 'fakeOnscreenEvent' and layoutID of 'fakeLayoutID'",
      );
    }
  },
};
