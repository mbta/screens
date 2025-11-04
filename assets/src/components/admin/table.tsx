import _ from "lodash/fp";
import { useEffect, useState, useMemo } from "react";

import { fetch, type Config, type JSON } from "Util/admin";

import { baseFields } from "./fields";

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
              {baseFields.map(({ label, path }) => (
                <th key={path}>{label}</th>
              ))}
            </tr>

            <tr>
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
                <th colSpan={baseFields.length}>
                  Showing {rows.length} of {localScreensCount} total screens
                </th>
              </tr>
            )}
          </thead>

          <tbody>
            {rows.map(([id, config]) => (
              <tr key={id}>
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
