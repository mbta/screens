import _ from "lodash/fp";
import { type ComponentType, useMemo } from "react";

import { type Config, useModalDialog } from "Util/admin";

import { ALL_FIELDS, APP_FIELDS } from "./fields";

const EditDialog: ComponentType<{
  config: Config;
  onClose: () => void;
  selectedIDs: Set<string>;
  setScreens: (screens: Config["screens"]) => void;
}> = ({ config, onClose, selectedIDs, setScreens }) => {
  const { dialog, ref } = useModalDialog();

  const entries = useMemo(
    () => Object.entries(config.screens).filter(([id]) => selectedIDs.has(id)),
    [config, selectedIDs],
  );

  const fields = useMemo(() => {
    const appIds = _.uniq(entries.map(([, { app_id }]) => app_id));
    const fields = appIds.length === 1 ? APP_FIELDS[appIds[0]] : ALL_FIELDS;
    return fields.filter((field) => !field.isStatic);
  }, [entries]);

  return (
    <dialog className="admin-editor__dialog" onClose={onClose} ref={ref}>
      <h2>
        Editing {entries.length} screen{entries.length === 1 ? "" : "s"}
      </h2>

      {entries.length > 0 && (
        <table>
          <tbody>
            {fields.map(({ label, path, cell: Cell }) => {
              const firstValue = _.get(path, entries[0][1]);

              const hasMultipleValues =
                _.uniqWith(
                  _.isEqual,
                  entries.map(([, screen]) => _.get(path, screen)),
                ).length > 1;

              const setValues = (value) =>
                setScreens(
                  Object.fromEntries(
                    entries.map(([id, screen]) => [
                      id,
                      _.set(path, value, screen),
                    ]),
                  ),
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
                        <i>(multiple values)</i>
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

      <button onClick={() => dialog?.close()}>✓ Done editing</button>
    </dialog>
  );
};

export default EditDialog;
