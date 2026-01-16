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
  | "elevator_v2"
  | "gl_eink_v2"
  | "pre_fare_v2";

export type AppInfo = { name: string; hasAudio: boolean; variants: string[] };

export const SCREEN_APPS: { [key in AppId]: AppInfo } = {
  bus_eink_v2: { name: "Bus E-ink", hasAudio: true, variants: [] },
  bus_shelter_v2: { name: "Bus Shelter", hasAudio: true, variants: [] },
  busway_v2: { name: "Sectional", hasAudio: true, variants: [] },
  dup_v2: { name: "DUP", hasAudio: false, variants: ["new_departures"] },
  elevator_v2: { name: "Elevator", hasAudio: false, variants: [] },
  gl_eink_v2: { name: "GL E-ink", hasAudio: true, variants: [] },
  pre_fare_v2: { name: "Pre-Fare", hasAudio: true, variants: [] },
};

export const SCREEN_VENDORS = [
  "c3ms",
  "gds",
  "lg_mri",
  "mercury",
  "mimo",
  "outfront",
  "solari",
];

const DEFAULT_APP_PARAMS: { [key in AppId]: Screen["app_params"] } = {
  bus_eink_v2: {
    alerts: { stop_id: "" },
    departures: { sections: [] },
    evergreen_content: [],
    footer: { stop_id: "" },
    header: { stop_id: "" },
  },
  bus_shelter_v2: {
    alerts: { stop_id: "" },
    departures: { sections: [] },
    evergreen_content: [],
    footer: { stop_id: "" },
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
  elevator_v2: {
    accessible_path_image_here_coordinates: { x: 0, y: 0 },
    alternate_direction_text: "",
    elevator_id: "",
    evergreen_content: [],
  },
  gl_eink_v2: {
    alerts: { stop_id: "" },
    departures: { sections: [] },
    evergreen_content: [],
    footer: { stop_id: "" },
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
 * Set of attributes for forms and form elements which disable "auto" browser
 * behaviors like autocomplete and spell check.
 */
const AUTOLESS_ATTRIBUTES = {
  autoCapitalize: "off",
  autoComplete: "off",
  autoCorrect: "off",
  spellCheck: false,
} as const;

const gatherSelectOptions = (rows, columnId) => {
  const options = rows.map((row) => row.values[columnId]);
  const uniqueOptions = new Set(options);
  return Array.from(uniqueOptions) as string[];
};

const fetch = {
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

export { AUTOLESS_ATTRIBUTES, fetch, gatherSelectOptions };
