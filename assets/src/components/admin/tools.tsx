import { useMemo, useState } from "react";
import { fetch } from "Util/admin";

const API_PATH = "/api/admin/maintenance";
const IMPORT_PATH = "/api/admin/import_configs";

const Tools = () => {
  return (
    <main className="admin-page">
      <EvergreenContentCleanup />
      <ImportConfigs />
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
  const importConfigs = async () => {
    const { success, upserted, deleted, error } = await fetch.post(
      IMPORT_PATH,
      {},
    );

    if (success) {
      window.alert(
        `Imported ${upserted} screen configurations. Deleted ${deleted}.`,
      );
    } else {
      window.alert(`Import failed: ${error || "Unknown error"}`);
    }
  };

  return (
    <section>
      <h2>Import Screen Configurations</h2>
      <p>
        Load screen configurations from the JSON file into the DB. This will
        overwrite any existing configurations in Postgres.
      </p>
      <button type="button" onClick={importConfigs}>
        Import
      </button>
    </section>
  );
};

export default Tools;
