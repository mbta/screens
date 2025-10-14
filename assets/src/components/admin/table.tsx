import { type ComponentType, useEffect, useState, useMemo } from "react";
import { Link } from "react-router";

import {
  AUTOLESS_ATTRIBUTES,
  SCREEN_APPS,
  fetch,
  type Config,
  type JSON,
  type Screen,
} from "Util/admin";

type Field<T> = {
  label: string;
  cell: Cell<T>;
  filter?: Filter<T>;
};

type Cell<T> = ComponentType<{ object: T; update: (t: T) => void }>;
type Filter<T> = ComponentType<{
  update: (filter: ((t: T) => boolean) | undefined) => void;
}>;

const ifChanged = (
  input: HTMLInputElement | HTMLTextAreaElement,
  func: (value: string) => void,
) => {
  if (input.value !== input.defaultValue) func(input.value);
};

const tryParse = (text: string): JSON | undefined => {
  try {
    return JSON.parse(text);
  } catch (e) {
    if (e instanceof SyntaxError) {
      return undefined;
    } else {
      throw e;
    }
  }
};

const booleanFilter =
  <T,>(key: string): Filter<T> =>
  ({ update }) => {
    const filters = useMemo(
      () => ({
        none: undefined,
        true: (object: T) => !!object[key],
        false: (object: T) => !object[key],
      }),
      [],
    );

    return (
      <select onChange={(e) => update(filters[e.target.value])}>
        <option value="none"></option>
        <option value="true">true</option>
        <option value="false">false</option>
      </select>
    );
  };

const checkboxInput =
  <T,>(key: string): Cell<T> =>
  ({ object, update }) => (
    <input
      type="checkbox"
      checked={object[key]}
      onChange={(e) => update({ ...object, [key]: e.target.checked })}
    />
  );

const jsonInput =
  <T,>(key: string): Cell<T> =>
  ({ object, update }) => {
    const [isValid, setIsValid] = useState(true);

    const updateIfValid = (value) => {
      const json = tryParse(value);
      if (json !== undefined) update({ ...object, [key]: json });
    };

    return (
      <div className="admin-table__input-container">
        <textarea
          {...AUTOLESS_ATTRIBUTES}
          className="admin-table__textarea"
          defaultValue={JSON.stringify(object[key], null, 2)}
          onChange={(e) => setIsValid(tryParse(e.target.value) !== undefined)}
          onBlur={(e) => ifChanged(e.target, (value) => updateIfValid(value))}
        />
        {!isValid && (
          <div>
            <small>❗️ Invalid JSON — will not be saved</small>
          </div>
        )}
      </div>
    );
  };

const stringInput =
  <T,>(key: string): Cell<T> =>
  ({ object, update }) => (
    <input
      {...AUTOLESS_ATTRIBUTES}
      defaultValue={object[key]}
      onBlur={(e) =>
        ifChanged(e.target, (value) => update({ ...object, [key]: value }))
      }
    />
  );

const baseFields: Field<Screen>[] = [
  {
    label: "App",
    cell: ({ object: screen }) => SCREEN_APPS[screen.app_id].name,
  },
  { label: "Name", cell: stringInput("name") },
  { label: "Location", cell: stringInput("location") },
  { label: "Vendor", cell: stringInput("vendor") },
  { label: "Device ID", cell: stringInput("device_id") },
  {
    label: "Disabled?",
    cell: checkboxInput("disabled"),
    filter: booleanFilter("disabled"),
  },
  {
    label: "Hidden?",
    cell: checkboxInput("hidden_from_screenplay"),
    filter: booleanFilter("hidden_from_screenplay"),
  },
  { label: "App Params", cell: jsonInput("app_params") },
];

const Table = () => {
  const [localScreens, setLocalScreens] = useState<Config["screens"]>({});
  const [remoteScreens, setRemoteScreens] = useState<Config["screens"]>({});
  const [filters, setFilters] = useState<
    Record<string, undefined | ((s: Screen) => boolean)>
  >({});

  const rows = useMemo(() => {
    const filterFns = Object.values(filters);

    return Object.entries(localScreens)
      .filter(([, config]) => filterFns.every((f) => !f || f(config)))
      .sort(([idA], [idB]) => idA.localeCompare(idB));
  }, [filters, localScreens]);

  const fetchConfig = async () => {
    const response = await fetch.get("/api/admin");
    const config: Config = JSON.parse(response.config);
    setLocalScreens(config.screens);
    setRemoteScreens(config.screens);
  };

  // Fetch config on mount
  useEffect(() => {
    fetchConfig();
    return;
  }, []);

  return (
    <main>
      {remoteScreens ? (
        <table className="admin-table">
          <thead>
            <tr>
              <th>ID</th>
              {baseFields.map(({ label, filter: Filter }) => (
                <th key={label}>
                  {label}
                  {Filter && (
                    <div>
                      <Filter
                        update={(filter) =>
                          setFilters({ ...filters, [label]: filter })
                        }
                      />
                    </div>
                  )}
                </th>
              ))}
            </tr>
          </thead>

          <tbody>
            {rows.map(([id, config]) => (
              <tr key={id}>
                <td>
                  <Link
                    to={`/inspector?id=${id}`}
                    className="admin-table__inspector-link"
                    title="🔍 View in Inspector"
                  >
                    {id}
                  </Link>
                </td>
                {baseFields.map(({ label, cell: Cell }) => (
                  <td key={label}>
                    <Cell
                      object={config}
                      update={(config) =>
                        setLocalScreens({ ...localScreens, [id]: config })
                      }
                    />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <p>Fetching data...</p>
      )}
    </main>
  );
};

export default Table;
