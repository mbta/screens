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
  path: string;
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

const BooleanFilter: Filter = ({ update }) => (
  <select onChange={(e) => update(BOOLEAN_FILTERS[e.target.value])}>
    <option value="none"></option>
    <option value="true">true</option>
    <option value="false">false</option>
  </select>
);

const buildSelectFilter =
  (options: string[]): Filter =>
  ({ update }) => (
    <select
      onChange={(e) =>
        update(e.target.value ? (value) => value == e.target.value : undefined)
      }
    >
      <option></option>
      {options.map((opt) => (
        <option key={opt} value={opt}>
          {opt}
        </option>
      ))}
    </select>
  );

const StringFilter: Filter = ({ update }) => (
  <input
    onChange={(e) =>
      update(
        e.target.value
          ? (value) =>
              typeof value == "string" &&
              value.toLowerCase().includes(e.target.value.toLowerCase())
          : undefined,
      )
    }
    placeholder="Search"
  />
);

const CheckboxInput: Cell = ({ value, update }) => (
  <input
    type="checkbox"
    checked={value as boolean}
    onChange={(e) => update(e.target.checked)}
  />
);

const JsonInput: Cell = ({ value, update }) => {
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

const buildSelectInput =
  (options: (string | null)[]): Cell =>
  ({ value, update }) => {
    const selectValue = (value as string | null) ?? undefined;

    return (
      <select onChange={(e) => update(e.target.value)} value={selectValue}>
        {options.map((opt) => (
          <option key={opt} value={opt ?? undefined}>
            {opt}
          </option>
        ))}
      </select>
    );
  };

const StringInput: Cell = ({ value, update }) => (
  <input
    {...AUTOLESS_ATTRIBUTES}
    defaultValue={value as string}
    onBlur={(e) => ifChanged(e.target, (v) => update(v || null))}
  />
);

const filteredStringCell = { cell: StringInput, filter: StringFilter };

const baseFields: Field[] = [
  {
    label: "App",
    path: "app_id",
    cell: ({ value }) => SCREEN_APPS[value as AppId].name,
  },
  { label: "Name", path: "name", ...filteredStringCell },
  { label: "Location", path: "location", ...filteredStringCell },
  {
    label: "Vendor",
    path: "vendor",
    cell: buildSelectInput([null, ...SCREEN_VENDORS]),
    filter: buildSelectFilter(SCREEN_VENDORS),
  },
  { label: "Device ID", path: "device_id", ...filteredStringCell },
  {
    label: "Disabled?",
    path: "disabled",
    cell: CheckboxInput,
    filter: BooleanFilter,
  },
  {
    label: "Hidden?",
    path: "hidden_from_screenplay",
    cell: CheckboxInput,
    filter: BooleanFilter,
  },
  { label: "App Params", path: "app_params", cell: JsonInput },
];

const Table = () => {
  const [localScreens, setLocalScreens] = useState<Config["screens"]>({});
  const [remoteScreens, setRemoteScreens] = useState<Config["screens"]>({});
  const [filters, setFilters] = useState<
    Record<string, undefined | ((v: JSON) => boolean)>
  >({});

  const localScreensCount = useMemo(
    () => Object.keys(localScreens).length,
    [localScreens],
  );

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
              {baseFields.map(({ label, path }) => (
                <th key={path}>{label}</th>
              ))}
            </tr>

            <tr>
              <th></th>
              {baseFields.map(({ filter: Filter, path }) => (
                <th key={path}>
                  {Filter && (
                    <Filter
                      update={(filter) =>
                        setFilters({ ...filters, [path]: filter })
                      }
                    />
                  )}
                </th>
              ))}
            </tr>

            {localScreensCount != rows.length && (
              <tr>
                <th colSpan={baseFields.length + 1}>
                  Showing {rows.length} out of {localScreensCount} total screens
                </th>
              </tr>
            )}
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

                {baseFields.map(({ cell: Cell, path }) => (
                  <td
                    className={
                      _.get(path, config) != _.get(path, remoteScreens[id])
                        ? "modified"
                        : undefined
                    }
                    key={path}
                  >
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
