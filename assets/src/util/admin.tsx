import getCsrfToken from "Util/csrf";

type JSONArray = Array<JSON>;
type JSONObject = { [key: string]: JSON };
type JSON = null | string | number | boolean | JSONArray | JSONObject;

export type Config = {
  screens: { [id: string]: Screen };
  devops: { disabled_modes: string[] };
};

export type Screen = {
  app_id: string;
  app_params: JSONObject;
  device_id: string | null;
  disabled: boolean;
  hidden_from_screenplay: boolean;
  name: string;
  vendor: string;
};

const gatherSelectOptions = (rows, columnId) => {
  const options = rows.map((row) => row.values[columnId]);
  const uniqueOptions = new Set(options);
  return Array.from(uniqueOptions);
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

  delete: (path) => doFetch(path, { method: "DELETE" }),

  text: (path) => doFetch(path, {}, (response) => response.text()),
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

export { fetch, gatherSelectOptions };
