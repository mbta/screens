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

const doSubmit = async (path, data) => {
  try {
    const result = await fetch(path, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-csrf-token": getCsrfToken(),
      },
      credentials: "include",
      body: JSON.stringify(data),
    });
    const json = await result.json();
    return json;
  } catch (err) {
    alert("An error occurred.");
    throw err;
  }
};

export { gatherSelectOptions, doSubmit };
