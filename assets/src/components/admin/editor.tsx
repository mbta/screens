import _ from "lodash/fp";
import { useMemo, useState } from "react";
import { useBlocker } from "react-router";

import {
  type AppId,
  type Config,
  SCREEN_APP_ENTRIES,
  fetch,
  useModalDialog,
  useResetKey,
} from "Util/admin";

import EditDialog from "./editor/edit_dialog";
import NewDialog from "./editor/new_dialog";
import Table from "./editor/table";

const EMPTY_CONFIG: Config = { screens: {}, devops: { disabled_modes: [] } };

const appIdFilters: { id: AppId | null; name: string }[] = [
  { id: null, name: "All" },
  ...SCREEN_APP_ENTRIES.map(([id, { name }]) => ({ id, name })),
];

const Editor = () => {
  const [didInitialize, setDidInitialize] = useState(false);
  const [isAddingScreen, setIsAddingScreen] = useState(false);
  const [isCommitReady, setIsCommitReady] = useState(false);
  const [isEditingScreens, setIsEditingScreens] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [localConfig, setLocalConfig] = useState<Config>(EMPTY_CONFIG);
  const [remoteConfig, setRemoteConfig] = useState<Config>(EMPTY_CONFIG);
  const [appIdFilter, setAppIdFilter] = useState<AppId | null>(null);
  const [selectedIDs, setSelectedIDs] = useState<Set<string>>(new Set());

  const { dialog: navBlockDialog, ref: navBlockDialogRef } = useModalDialog();

  // Some input components are "uncontrolled" to avoid triggering expensive
  // re-renders on every keystroke, but this means their values don't change
  // when updated "from the outside" via props. This unfortunately means any
  // time the config changes, we have to manually reset any mounted components
  // that didn't originate the update. Currently the table is the only component
  // this can apply to.
  const [tableDataKey, resetTableDataKey] = useResetKey();

  const newIDs = useMemo(
    () =>
      new Set(Object.keys(localConfig.screens)).difference(
        new Set(Object.keys(remoteConfig.screens)),
      ),
    [remoteConfig, localConfig],
  );

  const changedIDs = useMemo(
    () =>
      new Set(
        Object.entries(localConfig.screens)
          .filter(
            ([id, screen]) =>
              !newIDs.has(id) && !_.isEqual(screen, remoteConfig.screens[id]),
          )
          .map(([id]) => id),
      ),
    [localConfig, remoteConfig, newIDs],
  );

  const isChanged = changedIDs.size > 0 || newIDs.size > 0;

  const navBlocker = useBlocker(isChanged);

  const setScreens = (
    screens: Config["screens"],
    resetKeyFn: () => void = () => {},
  ) => {
    setLocalConfig({
      ...localConfig,
      screens: { ...localConfig.screens, ...screens },
    });
    setIsCommitReady(false);
    resetKeyFn();
  };

  const withInFlight = async (func: () => Promise<void>) => {
    setIsLoading(true);
    try {
      await func();
    } catch {
      window.alert("Error: Request failed.");
    } finally {
      setIsLoading(false);
    }
  };

  const reloadConfig = () => {
    withInFlight(async () => {
      const response = await fetch.get("/api/admin");
      const config: Config = JSON.parse(response.config);
      setLocalConfig(config);
      setRemoteConfig(config);
      setSelectedIDs(new Set());
      resetTableDataKey();
      setIsCommitReady(false);
    });
  };

  const validateConfig = () => {
    withInFlight(async () => {
      const { config } = await fetch.post("/api/admin/screens/validate", {
        config: JSON.stringify(localConfig),
      });
      setLocalConfig(config);
      resetTableDataKey();
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
    <main className="admin-editor">
      {navBlocker.state === "blocked" && (
        <dialog
          className="admin-editor__dialog"
          onClose={() => navBlocker.reset()}
          ref={navBlockDialogRef}
        >
          <h2>Unsaved changes</h2>
          <p>Leaving this page will discard your changes.</p>

          <button onClick={() => navBlocker.proceed()}>
            ⚠️ Discard changes
          </button>

          <button onClick={() => navBlockDialog?.close()}>
            ↩️ Back to editing
          </button>
        </dialog>
      )}

      {isAddingScreen && (
        <NewDialog
          config={localConfig}
          initialAppId={appIdFilter}
          onClose={() => setIsAddingScreen(false)}
          setScreens={(screens) => setScreens(screens, resetTableDataKey)}
        />
      )}

      {isEditingScreens && (
        <EditDialog
          config={localConfig}
          onClose={() => setIsEditingScreens(false)}
          selectedIDs={selectedIDs}
          setScreens={(screens) => setScreens(screens, resetTableDataKey)}
        />
      )}

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

      <div className="admin-editor__table">
        <Table
          appIdFilter={appIdFilter}
          changedIDs={changedIDs}
          dataKey={tableDataKey}
          isLoading={isLoading}
          localConfig={localConfig}
          newIDs={newIDs}
          remoteConfig={remoteConfig}
          selectedIDs={selectedIDs}
          setScreen={(id, screen) => setScreens({ [id]: screen })}
          setSelectedIDs={setSelectedIDs}
        />
      </div>

      <div className="admin-editor__footer">
        <button onClick={() => setIsAddingScreen(true)}>➕ New screen</button>

        <button
          disabled={selectedIDs.size === 0}
          onClick={() => setIsEditingScreens(true)}
        >
          🔹 Edit selected
        </button>

        {isCommitReady ? (
          <button disabled={isLoading} onClick={commitConfig}>
            ✅ Commit changes
          </button>
        ) : (
          <button disabled={!isChanged || isLoading} onClick={validateConfig}>
            🔸 Validate changes
          </button>
        )}

        <button
          disabled={isLoading}
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
    </main>
  );
};

export default Editor;
