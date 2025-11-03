import type { PropertyName } from "lodash";
import _ from "lodash/fp";
import { type ComponentType, useEffect, useState, useMemo } from "react";
import { Link } from "react-router";

import {
  AUTOLESS_ATTRIBUTES,
  SCREEN_APPS,
  SCREEN_VENDORS,
  fetch,
  type AppId,
  type Config,
  type JSON,
} from "Util/admin";

type Field = {
  label: string;
  path: PropertyName;
  cell: Cell;
  filter?: Filter;
};

type Cell = ComponentType<{ value: JSON; update: (value: JSON) => void }>;
type Filter = ComponentType<{
  update: (filter: ((value: JSON) => boolean) | undefined) => void;
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

const BOOLEAN_FILTERS = {
  none: undefined,
  true: (value: JSON) => !!value,
  false: (value: JSON) => !value,
};

const booleanFilter: Filter = ({ update }) => (
  <select onChange={(e) => update(BOOLEAN_FILTERS[e.target.value])}>
    <option value="none"></option>
    <option value="true">true</option>
    <option value="false">false</option>
  </select>
);

const checkboxInput: Cell = ({ value, update }) => (
  <input
    type="checkbox"
    checked={value as boolean}
    onChange={(e) => update(e.target.checked)}
  />
);

const jsonInput: Cell = ({ value, update }) => {
  const [isValid, setIsValid] = useState(true);

  const updateIfValid = (newValue) => {
    const json = tryParse(newValue);
    if (json !== undefined) update(json);
  };

  return (
    <div className="admin-table__input-container">
      <textarea
        {...AUTOLESS_ATTRIBUTES}
        className="admin-table__textarea"
        defaultValue={JSON.stringify(value, null, 2)}
        onChange={(e) => setIsValid(tryParse(e.target.value) !== undefined)}
        onBlur={(e) => ifChanged(e.target, updateIfValid)}
      />
      {!isValid && (
        <div>
          <small>❗️ Invalid JSON — will not be saved</small>
        </div>
      )}
    </div>
  );
};

const selectInput =
  (values: string[], includeNull?: boolean): Cell =>
  ({ value, update }) => (<select />);

const stringInput: Cell = ({ value, update }) => (
  <input
    {...AUTOLESS_ATTRIBUTES}
    defaultValue={value as string}
    onBlur={(e) => ifChanged(e.target, update)}
  />
);

const baseFields: Field[] = [
  {
    label: "App",
    path: "app_id",
    cell: ({ value }) => SCREEN_APPS[value as AppId].name,
  },
  { label: "Name", path: "name", cell: stringInput },
  { label: "Location", path: "location", cell: stringInput },
  { label: "Vendor", path: "vendor", cell: stringInput },
  { label: "Device ID", path: "device_id", cell: stringInput },
  {
    label: "Disabled?",
    path: "disabled",
    cell: checkboxInput,
    filter: booleanFilter,
  },
  {
    label: "Hidden?",
    path: "hidden_from_screenplay",
    cell: checkboxInput,
    filter: booleanFilter,
  },
  { label: "App Params", path: "app_params", cell: jsonInput },
];

const Table = () => {
  const [localScreens, setLocalScreens] = useState<Config["screens"]>({});
  const [remoteScreens, setRemoteScreens] = useState<Config["screens"]>({});
  const [filters, setFilters] = useState<
    Record<string, undefined | ((v: JSON) => boolean)>
  >({});

  const rows = useMemo(() => {
    const filterFns = Object.entries(filters);

    return Object.entries(localScreens)
      .filter(([, config]) =>
        filterFns.every(([path, fn]) => !fn || fn(_.get(path, config))),
      )
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
              {baseFields.map(({ label, path, filter: Filter }) => (
                <th key={label}>
                  {label}
                  {Filter && (
                    <div>
                      <Filter
                        update={(filter) =>
                          setFilters({ ...filters, [path]: filter })
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
                {baseFields.map(({ label, path, cell: Cell }) => (
                  <td key={label}>
                    <Cell
                      value={_.get(path, config)}
                      update={(value) =>
                        setLocalScreens({
                          ...localScreens,
                          [id]: _.set(path, value, config),
                        })
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
