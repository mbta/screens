import _ from "lodash/fp";
import { useState, useMemo } from "react";

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

const EMPTY_CONFIG: Config = { screens: {}, devops: { disabled_modes: [] } };

const appIdFilters: { id: AppId | null; name: string }[] = [
  { id: null, name: "All" },
  ...(Object.entries(SCREEN_APPS) as [AppId, AppInfo][]).map(
    ([id, { name }]) => ({ id, name }),
  ),
];

const get = (path: string, screen: Screen, id: string) =>
  path === "id" ? id : _.get(path, screen);

const Table = () => {
  const [didInitialize, setDidInitialize] = useState(false);
  const [isInFlight, setIsInFlight] = useState(false);
  const [isCommitReady, setIsCommitReady] = useState(false);
  const [localConfig, setLocalConfig] = useState<Config>(EMPTY_CONFIG);
  const [remoteConfig, setRemoteConfig] = useState<Config>(EMPTY_CONFIG);
  const [filters, setFilters] = useState<
    Record<string, undefined | ((v: JSON) => boolean)>
  >({});
  const [appIdFilter, setAppIdFilter] = useState<AppId | null>(null);
  const [filterResetKey, setFilterResetKey] = useState("");

  const fields = appIdFilter ? appFields[appIdFilter] : allFields;

  const rows = useMemo(() => {
    const filterFns = Object.entries(filters);

    return Object.entries(localConfig.screens)
      .filter(
        ([id, screen]) =>
          (appIdFilter === null || screen.app_id === appIdFilter) &&
          filterFns.every(([path, fn]) => !fn || fn(get(path, screen, id))),
      )
      .sort(([idA], [idB]) => idA.localeCompare(idB));
  }, [appIdFilter, filters, localConfig]);

  const counts = useMemo(() => {
    const visibleIDs = rows.map(([id]) => id);
    const modifiedIDs = Object.entries(localConfig.screens)
      .filter(([id, screen]) => !_.isEqual(screen, remoteConfig.screens[id]))
      .map(([id]) => id);

    return {
      remote: Object.keys(remoteConfig.screens).length,
      local: Object.keys(localConfig.screens).length,
      visible: visibleIDs.length,
      modified: modifiedIDs.length,
      visibleModified: _.intersection(visibleIDs, modifiedIDs).length,
    };
  }, [localConfig, remoteConfig, rows]);

  const isChanged = counts.modified > 0;
  const isFiltered = Object.values(filters).some((f) => f);

  const clearFilters = () => {
    // Since filter components are not "controlled", the easiest way to reset
    // the UI to the initial state is forcing a fresh mount by changing its
    // `key` to a new random value. This would need to be reconsidered if we
    // ever have a use case that involves *setting*, rather than just clearing,
    // a filter from outside the filter component that normally manages it.
    setFilters({});
    setFilterResetKey(window.crypto.randomUUID());
  }

  const setScreen = (id: string, screen: Screen) => {
    setLocalConfig({
      ...localConfig,
      screens: { ...localConfig.screens, [id]: screen },
    });
    setIsCommitReady(false);
  };

  const withInFlight = async (func: () => Promise<void>) => {
    setIsInFlight(true);
    await func();
    setIsInFlight(false);
  };

  const reloadConfig = () => {
    withInFlight(async () => {
      const response = await fetch.get("/api/admin");
      const config: Config = JSON.parse(response.config);
      setLocalConfig(config);
      setRemoteConfig(config);
      setIsCommitReady(false);
    });
  };

  const validateConfig = () => {
    withInFlight(async () => {
      const { config } = await fetch.post("/api/admin/screens/validate", {
        config: JSON.stringify(localConfig),
      });
      setLocalConfig(config);
      setIsCommitReady(true);
    });
  };

  const commitConfig = () => {
    withInFlight(async () => {
      const { success } = await fetch.post("/api/admin/screens/confirm", {
        config: JSON.stringify(localConfig),
      });

      if (success) {
        setRemoteConfig(localConfig);
        setIsCommitReady(false);
        window.alert("Config updated successfully.");
      } else {
        window.alert("Error: Config update failed.");
      }
    });
  };

  if (!didInitialize) {
    reloadConfig();
    setDidInitialize(true);
  }

  return (
    <main className="admin-table">
      <div className="admin-navbar">
        {appIdFilters.map(({ id, name }) => (
          <button
            key={id}
            className={id === appIdFilter ? "active" : undefined}
            onClick={() => setAppIdFilter(id)}
          >
            {name}
          </button>
        ))}
      </div>

      <div className="admin-table__table">
        <table>
          <thead>
            <tr>
              {fields.map(({ label, path }) => (
                <th key={path}>{label}</th>
              ))}
            </tr>

            <tr key={filterResetKey}>
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

            <tr>
              <th colSpan={fields.length}>
                <div className="admin-table__table__stats">
                  {isInFlight ? (
                    <span>Updating...</span>
                  ) : (
                    <>
                      <span>
                        {counts.visible < counts.local
                          ? `Showing ${counts.visible} of ${counts.local} screens`
                          : `Showing all ${counts.local} screens`}
                      </span>

                      {counts.modified > 0 && (
                        <span>
                          {counts.modified !== counts.visibleModified &&
                            `${counts.visibleModified} of`}{" "}
                          {counts.modified} modified
                        </span>
                      )}

                      {counts.local > counts.remote && (
                        <span>{counts.local - counts.remote} new</span>
                      )}

                      {isFiltered && (
                        <button onClick={clearFilters}>Clear filters</button>
                      )}
                    </>
                  )}
                </div>
              </th>
            </tr>
          </thead>

          <tbody>
            {rows.map(([id, screen]) => (
              <tr key={id}>
                {fields.map(({ cell: Cell, path }) => (
                  <td
                    className={
                      _.isEqual(
                        _.get(path, screen),
                        _.get(path, remoteConfig.screens[id]),
                      )
                        ? undefined
                        : "modified"
                    }
                    key={path}
                  >
                    <Cell
                      value={get(path, screen, id)}
                      update={(val) => setScreen(id, _.set(path, val, screen))}
                    />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="admin-table__footer">
        {isCommitReady ? (
          <button disabled={isInFlight} onClick={commitConfig}>
            Commit changes
          </button>
        ) : (
          <button disabled={!isChanged || isInFlight} onClick={validateConfig}>
            Validate changes
          </button>
        )}

        <button
          disabled={isInFlight}
          onClick={() => {
            if (
              !isChanged ||
              window.confirm("This will overwrite your changes. Are you sure?")
            ) {
              reloadConfig();
            }
          }}
        >
          Reload from server
        </button>
      </div>
    </main>
  );
};

export default Table;
