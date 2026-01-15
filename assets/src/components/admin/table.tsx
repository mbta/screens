import _ from "lodash/fp";
import { useState, useMemo, useRef } from "react";

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
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [didInitialize, setDidInitialize] = useState(false);
  const [isInFlight, setIsInFlight] = useState(false);
  const [isCommitReady, setIsCommitReady] = useState(false);
  const [localConfig, setLocalConfig] = useState<Config>(EMPTY_CONFIG);
  const [remoteConfig, setRemoteConfig] = useState<Config>(EMPTY_CONFIG);
  const [selectedIDs, setSelectedIDs] = useState<Set<string>>(new Set());
  const [filters, setFilters] = useState<
    Record<string, undefined | ((v: JSON) => boolean)>
  >({});
  const [appIdFilter, setAppIdFilter] = useState<AppId | null>(null);

  // Some Cell components are "uncontrolled" to avoid triggering expensive
  // re-renders on every keystroke, but this means their values don't change
  // when updated "from the outside"; the only way to sync them with new state
  // is to force a re-mount by changing their `key` (or the key of a containing
  // element/component).
  const [dialogResetKey, setDialogResetKey] = useState("");
  const [tableResetKey, setTableResetKey] = useState("");
  // The same is done with Filter components, but for a different reason: they
  // don't receive a value from props at all. This could be changed if we ever
  // have a need to *set* a filter "from the outside" rather than clearing it.
  const [filterResetKey, setFilterResetKey] = useState("");

  const fields = appIdFilter ? appFields[appIdFilter] : allFields;

  const fieldsForSelection = useMemo(() => {
    const appIds = _.uniq(
      [...selectedIDs].map((id) => localConfig.screens[id].app_id),
    );

    const fields = appIds.length === 1 ? appFields[appIds[0]] : allFields;
    return fields.filter((field) => !field.isStatic);
  }, [localConfig, selectedIDs]);

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

  const selectedRows: [string, Screen][] = useMemo(
    () => [...selectedIDs].map((id) => [id, localConfig.screens[id]]),
    [localConfig, selectedIDs],
  );

  const visibleIDs = useMemo(() => new Set(rows.map(([id]) => id)), [rows]);

  const counts = useMemo(() => {
    const modifiedIDs = new Set(
      Object.entries(localConfig.screens)
        .filter(([id, screen]) => !_.isEqual(screen, remoteConfig.screens[id]))
        .map(([id]) => id),
    );

    return {
      remote: Object.keys(remoteConfig.screens).length,
      local: Object.keys(localConfig.screens).length,
      visible: visibleIDs.size,
      modified: modifiedIDs.size,
      selected: selectedIDs.size,
      visibleModified: visibleIDs.intersection(modifiedIDs).size,
      visibleSelected: visibleIDs.intersection(selectedIDs).size,
    };
  }, [localConfig, remoteConfig, selectedIDs, visibleIDs]);

  const isChanged = counts.modified > 0;
  const isFiltered = Object.values(filters).some((f) => f);

  const clearFilters = () => {
    setFilters({});
    setFilterResetKey(window.crypto.randomUUID());
  };

  const setScreens = (
    screens: Config["screens"],
    setResetKey: (key: string) => void,
  ) => {
    setLocalConfig({
      ...localConfig,
      screens: { ...localConfig.screens, ...screens },
    });
    setIsCommitReady(false);
    setResetKey(window.crypto.randomUUID());
  };

  const setScreensFromDialog = (entries: [string, Screen][]) =>
    setScreens(Object.fromEntries(entries), setTableResetKey);

  const setScreenFromTable = (id: string, screen: Screen) =>
    setScreens({ [id]: screen }, setDialogResetKey);

  const updateSelected = (id: string, isSelected: boolean) =>
    setSelectedIDs(
      (prev) => (isSelected ? prev.add(id) : prev.delete(id), new Set(prev)),
    );

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
              <th></th>
              {fields.map(({ label, path }) => (
                <th key={path}>{label}</th>
              ))}
            </tr>

            <tr key={filterResetKey}>
              <th></th>
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
              <th colSpan={fields.length + 1}>
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

                      {counts.selected > 0 && (
                        <span>
                          {counts.selected !== counts.visibleSelected &&
                            `${counts.visibleSelected} of`}{" "}
                          {counts.selected} selected
                        </span>
                      )}

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
                        <span>
                          <button onClick={clearFilters}>Clear filters</button>
                        </span>
                      )}

                      {!(
                        selectedIDs.size === visibleIDs.size &&
                        selectedIDs.isSubsetOf(visibleIDs)
                      ) && (
                        <span>
                          <button
                            onClick={() => setSelectedIDs(new Set(visibleIDs))}
                          >
                            Select visible
                          </button>
                        </span>
                      )}

                      {counts.selected > 0 && (
                        <span>
                          <button onClick={() => setSelectedIDs(new Set())}>
                            Clear selection
                          </button>
                        </span>
                      )}
                    </>
                  )}
                </div>
              </th>
            </tr>
          </thead>

          <tbody key={tableResetKey}>
            {rows.map(([id, screen]) => (
              <tr
                key={id}
                className={selectedIDs.has(id) ? "selected" : undefined}
              >
                <td className="select">
                  <input
                    type="checkbox"
                    checked={selectedIDs.has(id)}
                    onChange={(e) => updateSelected(id, e.target.checked)}
                  />
                </td>

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
                      update={(val) =>
                        setScreenFromTable(id, _.set(path, val, screen))
                      }
                    />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="admin-table__footer">
        <button
          disabled={selectedIDs.size === 0}
          onClick={() => dialogRef.current?.showModal()}
        >
          🔹 Edit selected
        </button>

        {isCommitReady ? (
          <button disabled={isInFlight} onClick={commitConfig}>
            Commit changes
          </button>
        ) : (
          <button disabled={!isChanged || isInFlight} onClick={validateConfig}>
            🔸 Validate changes
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
          🔄 Reload from server
        </button>
      </div>

      <dialog className="admin-table__dialog" ref={dialogRef}>
        <h2>Editing {selectedIDs.size} screens</h2>

        {selectedIDs.size > 0 && (
          <table>
            <tbody key={dialogResetKey}>
              {fieldsForSelection.map(({ label, path, cell: Cell }) => {
                const firstValue = get(
                  path,
                  selectedRows[0][1],
                  selectedRows[0][0],
                );

                const hasMultipleValues =
                  _.uniq(
                    selectedRows.map(([id, screen]) => get(path, screen, id)),
                  ).length > 1;

                const setValues = (value) =>
                  setScreensFromDialog(
                    selectedRows.map(([id, screen]) => [
                      id,
                      _.set(path, value, screen),
                    ]),
                  );

                return (
                  <tr key={path}>
                    <th>{label}</th>

                    <td>
                      {hasMultipleValues ? (
                        <span>
                          <button
                            onClick={() => {
                              if (
                                window.confirm(
                                  "Set all selected screens to the same value?",
                                )
                              ) {
                                setValues(firstValue);
                              }
                            }}
                          >
                            🔓
                          </button>{" "}
                          (multiple values)
                        </span>
                      ) : (
                        <Cell value={firstValue} update={setValues} />
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}

        <button onClick={() => dialogRef.current?.close()}>Done editing</button>
      </dialog>
    </main>
  );
};

export default Table;
