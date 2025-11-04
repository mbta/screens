import _ from "lodash/fp";
import { useEffect, useState, useMemo } from "react";

import {
  type AppId,
  type Config,
  type JSON,
  type Screen,
  SCREEN_APPS,
  fetch,
  AppInfo,
} from "Util/admin";

import { allFields, appFields } from "./fields";

const appIdFilters: { id: AppId | null; name: string }[] = [
  { id: null, name: "All" },
  ...(Object.entries(SCREEN_APPS) as [AppId, AppInfo][]).map(
    ([id, { name }]) => ({ id, name }),
  ),
];

const get = (path: string, screen: Screen, id: string) =>
  path == "id" ? id : _.get(path, screen);

const Table = () => {
  const [localScreens, setLocalScreens] = useState<Config["screens"]>({});
  const [remoteScreens, setRemoteScreens] = useState<Config["screens"]>({});
  const [filters, setFilters] = useState<
    Record<string, undefined | ((v: JSON) => boolean)>
  >({});
  const [appIdFilter, setAppIdFilter] = useState<AppId | null>(null);

  const localScreensCount = useMemo(
    () => Object.keys(localScreens).length,
    [localScreens],
  );

  const fields = appIdFilter ? appFields[appIdFilter] : allFields;

  const rows = useMemo(() => {
    const filterFns = Object.entries(filters);

    return Object.entries(localScreens)
      .filter(([id, screen]) =>
        (appIdFilter == null || screen.app_id == appIdFilter) &&
        filterFns.every(([path, fn]) => !fn || fn(get(path, screen, id))),
      )
      .sort(([idA], [idB]) => idA.localeCompare(idB));
  }, [appIdFilter, filters, localScreens]);

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
      <div className="admin-navbar">
        {appIdFilters.map(({ id, name }) => (
          <button
            key={id}
            className={id == appIdFilter ? "active" : undefined}
            onClick={() => setAppIdFilter(id)}
          >
            {name}
          </button>
        ))}
      </div>

      {remoteScreens ? (
        <table className="admin-table">
          <thead>
            <tr>
              {fields.map(({ label, path }) => (
                <th key={path}>{label}</th>
              ))}
            </tr>

            <tr>
              {fields.map(({ filter: Filter, path }) => (
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
                <th colSpan={fields.length}>
                  Showing {rows.length} of {localScreensCount} total screens
                </th>
              </tr>
            )}
          </thead>

          <tbody>
            {rows.map(([id, screen]) => (
              <tr key={id}>
                {fields.map(({ cell: Cell, path }) => (
                  <td
                    className={
                      _.get(path, screen) != _.get(path, remoteScreens[id])
                        ? "modified"
                        : undefined
                    }
                    key={path}
                  >
                    <Cell
                      value={get(path, screen, id)}
                      update={(value) =>
                        setLocalScreens({
                          ...localScreens,
                          [id]: _.set(path, value, screen),
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
