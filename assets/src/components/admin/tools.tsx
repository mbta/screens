import { useEffect, useMemo, useState } from "react";
import { fetch } from "Util/admin";

const API_PATH = "/api/admin/maintenance";
const IMPORT_PATH = "/api/admin/import_configs";
const SYNC_ENVIRONMENTS_PATH = "/api/admin/sync_environments";
const SYNC_FROM_SNAPSHOT_PATH = "/api/admin/sync_from_snapshot";

const Tools = () => {
  return (
    <main className="admin-page">
      <EvergreenContentCleanup />
      <ImportConfigs />
      <SyncFromSnapshot />
    </main>
  );
};

const EvergreenContentCleanup = () => {
  const today = useMemo(() => new Date().toISOString().split("T")[0], []);
  const [contentCleanupDate, setContentCleanupDate] = useState(today);

  const cleanupContent = async () => {
    const doRequest = (params = {}) =>
      fetch.post(API_PATH, {
        ...params,
        action: "content_cleanup",
        before: contentCleanupDate,
      });

    const { affected } = await doRequest({ dry_run: true });

    if (affected > 0) {
      const prompt =
        `Delete evergreen content that ended before ${contentCleanupDate}? ` +
        `This will affect ${affected} screens.`;

      if (window.confirm(prompt)) {
        const { success } = await doRequest();

        window.alert(
          success
            ? "Configuration updated."
            : "Error: Configuration update failed.",
        );
      }
    } else {
      window.alert("No screens would be affected.");
    }
  };

  return (
    <section>
      <h2>Evergreen Content Cleanup</h2>
      <p>
        Delete inactive evergreen content which ended before the specified date.
      </p>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          cleanupContent();
        }}
      >
        <input
          type="date"
          max={today}
          value={contentCleanupDate}
          onChange={(event) => setContentCleanupDate(event.target.value)}
        />
        <button type="submit">Cleanup</button>
      </form>
    </section>
  );
};

// This section should be a part of post_config_migration_cleanup
const ImportConfigs = () => {
  const [isImporting, setIsImporting] = useState(false);

  const importConfigs = async () => {
    // Shouldn't happen, but just in case the button is clicked multiple times
    if (isImporting) return;

    if (
      !window.confirm(
        "Are you sure? This will overwrite existing configurations in Postgres with the JSON file in S3.",
      )
    ) {
      return;
    }

    setIsImporting(true);

    const { status, upserted, deleted, error } = await fetch.post(
      IMPORT_PATH,
      {},
    );

    setIsImporting(false);

    if (status === 200) {
      window.alert(`Imported ${upserted} configurations. Deleted ${deleted}.`);
    } else {
      window.alert(`Import failed: ${error || "Unknown error"}`);
    }
  };

  return (
    <section>
      <h2>Import Screen Configurations to Postgres</h2>
      <p>
        Load screen configurations from the JSON file into our DB. This will
        overwrite any existing configurations in Postgres.
      </p>
      <button type="button" onClick={importConfigs} disabled={isImporting}>
        Import
      </button>
    </section>
  );
};

const SyncFromSnapshot = () => {
  const [environments, setEnvironments] = useState<string[]>([]);
  const [environment, setEnvironment] = useState("");
  const [isRestoring, setIsRestoring] = useState(false);

  useEffect(() => {
    fetch.get(SYNC_ENVIRONMENTS_PATH).then(({ environments }) => {
      setEnvironments(environments);
      setEnvironment(environments[0] ?? "");
    });
  }, []);

  const restore = async () => {
    if (isRestoring || environment === "") return;

    if (
      !window.confirm(
        `Overwrite all screen configurations and assets with the latest backup from "${environment}"? ` +
          "Configurations that don't exist in the backup will be deleted.",
      )
    ) {
      return;
    }

    setIsRestoring(true);
    const { status, upserted, deleted, assets_copied, error } =
      await fetch.post(SYNC_FROM_SNAPSHOT_PATH, { environment });
    setIsRestoring(false);

    if (status === 200) {
      window.alert(
        `Restored ${upserted} configurations. Deleted ${deleted}. Copied ${assets_copied} assets.`,
      );
    } else {
      window.alert(`Restore failed: ${error || "Unknown error"}`);
    }
  };

  // There will be no environments to restore from in production, so don't show this section.
  if (environments.length === 0) return null;

  // Display different prompt locally where we don't have assets in S3 to copy over
  const configSyncPrompt =
    "Replace all screen configurations in Postgres with the latest snapshot of the selected environment. ";
  const assetSyncPrompt = ` Assets from the source environment will also be copied over in S3.`;
  const fullBackupPrompt =
    configSyncPrompt + (environments[0] === "local" ? "" : assetSyncPrompt);

  return (
    <section>
      <h2>Sync Configurations from Source Environment</h2>
      <p> {fullBackupPrompt} </p>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          restore();
        }}
      >
        <select
          value={environment}
          onChange={(event) => setEnvironment(event.target.value)}
        >
          {environments.map((name) => (
            <option key={name} value={name}>
              {name}
            </option>
          ))}
        </select>
        <button type="submit" disabled={isRestoring}>
          Sync
        </button>
      </form>
    </section>
  );
};

export default Tools;
