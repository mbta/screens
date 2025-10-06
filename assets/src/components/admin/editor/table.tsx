import cx from "classnames";
import _ from "lodash/fp";
import {
  type ComponentType,
  type Dispatch,
  type Key,
  type SetStateAction,
  useMemo,
  useState,
} from "react";

import {
  type AppId,
  type Config,
  type JSON,
  type Screen,
  useResetKey,
} from "Util/admin";

import { ALL_FIELDS, APP_FIELDS } from "./fields";

// Pretend `id` is a field on screens (see the "ID" field in `./fields`)
const get = (path: string, screen: Screen, id: string) =>
  path === "id" ? id : _.get(path, screen);

const Table: ComponentType<{
  appIdFilter: AppId | null;
  changedIDs: Set<string>;
  dataKey: Key;
  isLoading: boolean;
  localConfig: Config;
  newIDs: Set<string>;
  remoteConfig: Config;
  selectedIDs: Set<string>;
  setScreen: (id: string, screen: Screen) => void;
  setSelectedIDs: Dispatch<SetStateAction<Set<string>>>;
}> = ({
  appIdFilter,
  changedIDs,
  dataKey,
  isLoading,
  localConfig,
  newIDs,
  remoteConfig,
  selectedIDs,
  setScreen,
  setSelectedIDs,
}) => {
  const [filters, setFilters] = useState<
    Record<string, undefined | ((v: JSON) => boolean)>
  >({});

  // Filter components are "uncontrolled", so to make them update their
  // displayed value when "Clear filters" is used, we have to re-mount them.
  // This could be changed if we ever have a need to *set* a filter "from the
  // outside" rather than just clearing it.
  const [filtersKey, resetFiltersKey] = useResetKey();

  const clearFilters = () => {
    setFilters({});
    resetFiltersKey();
  };

  const fields = appIdFilter ? APP_FIELDS[appIdFilter] : ALL_FIELDS;

  const isFiltered = Object.values(filters).some((f) => f);

  const rows = useMemo(() => {
    const filterFns = Object.entries(filters);

    return Object.entries(localConfig.screens)
      .filter(
        ([id, screen]) =>
          (appIdFilter === null || screen.app_id === appIdFilter) &&
          filterFns.every(([path, fn]) => !fn || fn(get(path, screen, id))),
      )
      .sort(([idA], [idB]) =>
        newIDs.has(idA) && !newIDs.has(idB)
          ? -1
          : newIDs.has(idB) && !newIDs.has(idA)
            ? 1
            : idA.localeCompare(idB),
      );
  }, [appIdFilter, filters, localConfig, newIDs]);

  const updateSelected = (id: string, isSelected: boolean) =>
    setSelectedIDs(
      (prev) => (isSelected ? prev.add(id) : prev.delete(id), new Set(prev)),
    );

  const visibleIDs = useMemo(() => new Set(rows.map(([id]) => id)), [rows]);

  const counts = useMemo(() => {
    return {
      total: Object.keys(localConfig.screens).length,
      visible: visibleIDs.size,
      changed: changedIDs.size,
      new: newIDs.size,
      selected: selectedIDs.size,
      visibleChanged: visibleIDs.intersection(changedIDs).size,
      visibleNew: visibleIDs.intersection(newIDs).size,
      visibleSelected: visibleIDs.intersection(selectedIDs).size,
    };
  }, [localConfig, changedIDs, newIDs, selectedIDs, visibleIDs]);

  return (
    <table>
      <thead>
        <tr>
          <th></th>
          {fields.map(({ label, path }) => (
            <th key={path}>{label}</th>
          ))}
        </tr>

        <tr key={filtersKey}>
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
          <th></th>
          <th colSpan={fields.length}>
            <div className="admin-editor__table__stats">
              {isLoading ? (
                <span>Updating...</span>
              ) : (
                <>
                  <span>
                    {counts.visible < counts.total
                      ? `Showing ${counts.visible} of ${counts.total} screens`
                      : `Showing all ${counts.total} screens`}
                  </span>

                  {counts.selected > 0 && (
                    <span>
                      {counts.selected !== counts.visibleSelected &&
                        `${counts.visibleSelected} of`}{" "}
                      {counts.selected} selected
                    </span>
                  )}

                  {counts.changed > 0 && (
                    <span>
                      {counts.changed !== counts.visibleChanged &&
                        `${counts.visibleChanged} of`}{" "}
                      {counts.changed} changed
                    </span>
                  )}

                  {counts.new > 0 && (
                    <span>
                      {counts.new !== counts.visibleNew &&
                        `${counts.visibleNew} of`}{" "}
                      {counts.new} new
                    </span>
                  )}

                  {isFiltered && (
                    <button onClick={clearFilters}>Clear filters</button>
                  )}

                  {!(
                    selectedIDs.size === visibleIDs.size &&
                    selectedIDs.isSubsetOf(visibleIDs)
                  ) && (
                    <button onClick={() => setSelectedIDs(new Set(visibleIDs))}>
                      Select visible
                    </button>
                  )}

                  {counts.selected > 0 && (
                    <button onClick={() => setSelectedIDs(new Set())}>
                      Clear selection
                    </button>
                  )}
                </>
              )}
            </div>
          </th>
        </tr>
      </thead>

      <tbody key={dataKey}>
        {rows.map(([id, screen]) => (
          <tr
            key={id}
            className={cx({
              changed: changedIDs.has(id) || newIDs.has(id),
              selected: selectedIDs.has(id),
            })}
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
                className={cx({
                  changed:
                    !newIDs.has(id) &&
                    !_.isEqual(
                      _.get(path, screen),
                      _.get(path, remoteConfig.screens[id]),
                    ),
                })}
                key={path}
              >
                <Cell
                  value={get(path, screen, id)}
                  update={(val) => setScreen(id, _.set(path, val, screen))}
                  isNewScreen={newIDs.has(id)}
                />
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default Table;
