import { type ComponentType, useMemo, useState } from "react";

import {
  type AppId,
  type Config,
  AUTOLESS_ATTRIBUTES,
  SCREEN_APP_ENTRIES,
  newScreen,
  useModalDialog,
} from "Util/admin";

const NewDialog: ComponentType<{
  config: Config;
  initialAppId: AppId | null;
  onClose: () => void;
  setScreens: (screens: Config["screens"]) => void;
}> = ({ config, initialAppId, onClose, setScreens }) => {
  const { dialog, ref } = useModalDialog();
  const [screenId, setScreenId] = useState("");
  const [appId, setAppId] = useState(initialAppId);

  const existingIds = useMemo(
    () => new Set(Object.keys(config.screens)),
    [config],
  );

  const hasIdConflict = existingIds.has(screenId);

  return (
    <dialog className="admin-editor__dialog" onClose={onClose} ref={ref}>
      <h2>New screen</h2>

      <form
        method="dialog"
        onSubmit={() => setScreens({ [screenId]: newScreen(appId as AppId) })}
      >
        <table>
          <tbody>
            <tr>
              <th>App</th>
              <td>
                <select
                  value={appId ?? undefined}
                  onChange={(e) => setAppId((e.target.value as AppId) ?? null)}
                >
                  <option></option>
                  {SCREEN_APP_ENTRIES.map(([appId, { name }]) => (
                    <option key={appId} value={appId}>
                      {name}
                    </option>
                  ))}
                </select>
              </td>
              <td></td>
            </tr>

            <tr>
              <th>ID</th>
              <td>
                <input
                  {...AUTOLESS_ATTRIBUTES}
                  value={screenId}
                  onChange={(e) => setScreenId(e.target.value)}
                  /* https://github.com/facebook/react/issues/23301 */
                  ref={(elem) => elem?.setAttribute("autofocus", "")}
                />
              </td>
              <td>
                {hasIdConflict && <small>❗️ Screen ID already exists</small>}
              </td>
            </tr>
          </tbody>
        </table>

        <button type="submit" disabled={!appId || !screenId || hasIdConflict}>
          ✓ Confirm
        </button>

        <button type="button" onClick={() => dialog?.close()}>
          × Cancel
        </button>
      </form>
    </dialog>
  );
};

export default NewDialog;
