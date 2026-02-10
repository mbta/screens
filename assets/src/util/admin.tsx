import { type Key, type RefCallback, useState } from "react";
import getCsrfToken from "Util/csrf";

type JSONArray = Array<JSON>;
type JSONObject = { [key: string]: JSON };
export type JSON = null | string | number | boolean | JSONArray | JSONObject;

export type Config = {
  screens: { [id: string]: Screen };
  devops: { disabled_modes: string[] };
};

export type Screen = {
  app_id: AppId;
  app_params: JSONObject;
  device_id: string | null;
  disabled: boolean;
  hidden_from_screenplay: boolean;
  name: string | null;
  location: string | null;
  tags: string[];
  vendor: keyof typeof SCREEN_VENDORS | null;
};

export type ScreenWithId = { id: string; config: Screen };

export type AppId =
  | "bus_eink_v2"
  | "bus_shelter_v2"
  | "busway_v2"
  | "dup_v2"
  | "gl_eink_v2"
  | "pre_fare_v2";

type AppInfo = { name: string; hasAudio: boolean; variants: string[] };

export const SCREEN_APPS: { [key in AppId]: AppInfo } = {
  bus_eink_v2: { name: "Bus E-ink", hasAudio: true, variants: [] },
  bus_shelter_v2: { name: "Bus Shelter", hasAudio: true, variants: [] },
  busway_v2: { name: "Sectional", hasAudio: true, variants: [] },
  dup_v2: { name: "DUP", hasAudio: false, variants: ["new_departures"] },
  gl_eink_v2: { name: "GL E-ink", hasAudio: true, variants: [] },
  pre_fare_v2: { name: "Pre-Fare", hasAudio: true, variants: [] },
};

export const SCREEN_APP_ENTRIES = (
  Object.entries(SCREEN_APPS) as [AppId, AppInfo][]
).sort(([, { name: nameA }], [, { name: nameB }]) =>
  nameA.localeCompare(nameB),
);

export const SCREEN_VENDORS = [
  "c3ms",
  "gds",
  "lg_mri",
  "mercury",
  "outfront",
  "solari",
];

const DEFAULT_APP_PARAMS: { [key in AppId]: Screen["app_params"] } = {
  bus_eink_v2: {
    alerts: { stop_id: "" },
    departures: { sections: [] },
    evergreen_content: [],
    footer: { stop_id: null },
    header: { stop_id: "" },
  },
  bus_shelter_v2: {
    alerts: { stop_id: "" },
    departures: { sections: [] },
    evergreen_content: [],
    footer: { stop_id: null },
    header: { stop_id: "" },
  },
  busway_v2: {
    departures: { sections: [] },
    evergreen_content: [],
    header: { stop_name: "" },
  },
  dup_v2: {
    alerts: { stop_id: "" },
    evergreen_content: [],
    header: { stop_id: "" },
    primary_departures: { sections: [] },
    secondary_departures: { sections: [] },
  },
  gl_eink_v2: {
    alerts: { stop_id: "" },
    departures: { sections: [] },
    evergreen_content: [],
    footer: { stop_id: null },
    header: { stop_id: "" },
  },
  pre_fare_v2: {
    evergreen_content: [],
    header: { stop_id: "" },
  },
};

/**
 * Initialize a new screen. The app params will be "valid" insofar as the admin
 * UI can edit the screen without crashing, but may need further editing by the
 * user to actually be valid configuration.
 */
export const newScreen = (appId: AppId) => ({
  app_id: appId,
  app_params: DEFAULT_APP_PARAMS[appId],
  device_id: null,
  disabled: false,
  hidden_from_screenplay: true,
  name: null,
  location: null,
  tags: [],
  vendor: null,
});

/**
 * Convenience hook for use with modal `<dialog>`s that are not mounted until
 * they are ready to be shown. There is no need for this hook if having the
 * `<dialog>` always mounted is acceptable (and in most cases it should be).
 */
export const useModalDialog = (): {
  dialog: HTMLDialogElement | null;
  ref: RefCallback<HTMLDialogElement>;
} => {
  const [dialog, setDialog] = useState<HTMLDialogElement | null>(null);

  return {
    dialog,
    ref: (elem) => {
      setDialog(elem);
      if (elem) elem.showModal();
    },
  };
};

/**
 * Provides a React `key`-compatible state value and a function that updates it
 * to a new unique value. Can be used to force a component to re-mount.
 */
export const useResetKey = (): [Key, () => void] => {
  const [key, setKey] = useState("");
  return [key, () => setKey(window.crypto.randomUUID())];
};

/**
 * Set of attributes for forms and form elements which disable "auto" browser
 * behaviors like autocomplete and spell check.
 */
export const AUTOLESS_ATTRIBUTES = {
  autoCapitalize: "off",
  autoComplete: "off",
  autoCorrect: "off",
  spellCheck: false,
} as const;

export const fetch = {
  get: (path) => doFetch(path, {}),

  post: (path, data) => {
    return doFetch(path, {
      body: JSON.stringify(data),
      headers: {
        "content-type": "application/json",
        "x-csrf-token": getCsrfToken(),
      },
      method: "POST",
    });
  },

  delete: (path) =>
    doFetch(path, {
      method: "DELETE",
      headers: {
        "x-csrf-token": getCsrfToken(),
      },
    }),

  text: (path) => doFetch(path, {}, (response) => response.text()),

  formData: (path: string, data: FormData) => {
    return doFetch(path, {
      body: data,
      headers: {
        "x-csrf-token": getCsrfToken(),
      },
      method: "POST",
    });
  },
};

const doFetch = async (
  path,
  opts,
  handleResponse = (response) => response.json(),
) => {
  try {
    const response = await window.fetch(path, opts);

    if (response.status === 401) {
      alert("Your session has expired; refresh the page to continue.");
      throw new Error("unauthenticated");
    } else {
      return handleResponse(response);
    }
  } catch (error) {
    alert(`An error occurred: ${error}`);
    throw error;
  }
};
