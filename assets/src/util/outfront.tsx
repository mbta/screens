import { ROTATION_INDEX } from "Components/v2/dup/rotation_index";
import { getDatasetValue } from "Util/dataset";

/**
 * Returns true if this client is running on an Outfront Media screen.
 * (A DUP or a triptych.)
 *
 * Use this for OFM-specific logic that is common to both the DUP and triptych apps.
 */
export const isOFM = () => location.href.startsWith("file:");

/**
 * Returns true if this client is running on a DUP screen.
 *
 * Use this for DUP-specific logic.
 */
export const isDup = () => /^file:.*dup-app.*/.test(location.href);

/**
 * Returns true if this client is running on a triptych screen.
 *
 * Use this for triptych-specific logic.
 */
export const isTriptych = () => /^file:.*triptych-app.*/.test(location.href);

type RotationIndex = "0" | "1" | "2";
const isRotationIndex = (value: any): value is RotationIndex => {
  return value === "0" || value === "1" || value === "2";
};

export type TriptychPane = "left" | "middle" | "right";
const isTriptychPane = (value: any): value is TriptychPane => {
  return value === "left" || value === "middle" || value === "right";
};

export const getRotationIndex = (): RotationIndex | null => {
  const rotationIndex = isOFM()
    ? ROTATION_INDEX.toString()
    : getDatasetValue("rotationIndex");

  return isRotationIndex(rotationIndex) ? rotationIndex : null;
};

/**
 * Gets Outfront's unique name/ID for the media player we're running on.
 *
 * For DUPs, this is just a single ID. For triptychs, each of the 3 panes has its own player name.
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
 * Determines which of the 3 panes of a triptych we're running on (left, middle, or right).
 *
 * If we're running on a real triptych screen, we determine the pane from the `Array_configuration` tag.
 * If we're running in a browser, we determine the pane from the `data-triptych-pane` attribute on the #app div.
 *
 * Returns null if we fail to determine the pane for any reason.
 */
export const getTriptychPane = (): TriptychPane | null => {
  const pane = isTriptych()
    ? getTriptychPaneFromTags()
    : getDatasetValue("triptychPane");

  return isTriptychPane(pane) ? pane : null;
};

const getTriptychPaneFromTags = () => {
  let pane: TriptychPane | null = null;

  const tags = getTags();
  if (tags !== null) {
    const arrayConfiguration =
      tags.find(({ name }) => name === "Array_configuration")?.value?.[0] ??
      null;
    pane = arrayConfigurationToTriptychPane(arrayConfiguration);
  }

  return pane;
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

const arrayConfigurationToTriptychPane = (
  arrayConfiguration: string | null,
): TriptychPane | null => {
  switch (arrayConfiguration) {
    case "Triple_Left":
      return "left";
    case "Triple_Middle":
      return "middle";
    case "Triple_Right":
      return "right";
    default:
      return null;
  }
};

const triptychPaneToArrayConfiguration = (pane: TriptychPane): string => {
  return `Triple_${pane[0].toUpperCase().concat(pane.slice(1))}`;
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
  if (!isOFM()) return false;
  return (parent?.parent as OFMWindow)?.mraid ?? false;
};

/**
 * For use in test DUP/triptych packages only! Sets a fake MRAID object on `window` so that we can test OFM client packages
 * as if they are running on real OFM screens.
 */
export const __TEST_setFakeMRAID__ = (options: {
  playerName: string;
  station: string;
  triptychPane?: TriptychPane;
}) => {
  const { playerName, station, triptychPane } = options;

  const tags: OFMTag[] = [{ name: "Station", value: [station] }];
  if (triptychPane) {
    tags.push({
      name: "Array_configuration",
      value: [triptychPaneToArrayConfiguration(triptychPane)],
    });
  }
  const tagsJSON = JSON.stringify({ tags });

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
