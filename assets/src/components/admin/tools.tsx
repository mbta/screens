import { useEffect, useMemo, useState } from "react";
import RestoreFromBackup from "Components/admin/tools/restore_from_backup";
import { adminEnvironment, fetch } from "Util/admin";

const API_PATH = "/api/admin/maintenance";
const SYNC_ENVIRONMENTS_PATH = "/api/admin/sync_environments";
const SYNC_FROM_SNAPSHOT_PATH = "/api/admin/sync_from_snapshot";

const Tools = () => {
  return (
    <main className="admin-page admin-tools">
      <ContentCleanup />
      <SyncFromSnapshot />
      <RestoreFromBackup />
    </main>
  );
};

const ContentCleanup = () => {
  return (
    <section>
      <h2>Content Cleanup</h2>
      <ScheduledContentCleanup />
      <AlertContentCleanup />
      <UnusedAssetCleanup />
    </section>
  );
};

const ScheduledContentCleanup = () => {
  const today = useMemo(() => new Date().toISOString().split("T")[0], []);
  const [contentCleanupDate, setContentCleanupDate] = useState(today);

  const cleanupContent = async () => {
    const doRequest = (params = {}) =>
      fetch.post(API_PATH, {
        ...params,
        action: "image_content_cleanup",
        before: contentCleanupDate,
      });

    const { affected } = await doRequest({ dry_run: true });

    if (affected > 0) {
      const prompt =
        `Delete evergreen and wayfinding content that ended before ${contentCleanupDate}? ` +
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
      <h3>Schedule-Based Config Cleanup</h3>
      <p>
        Delete inactive evergreen and wayfinding content which ended before the
        specified date.
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
        <button type="submit">Preview Cleanup</button>
      </form>
    </section>
  );
};

const AlertContentCleanup = () => {
  const [isRunning, setIsRunning] = useState(false);

  const cleanupContent = async () => {
    const dryRun = await fetch.post(API_PATH, {
      action: "alert_content_cleanup",
      dry_run: true,
    });

    if (dryRun.status !== 200) {
      window.alert(`Error: ${dryRun.error || "Unknown error"}`);
      return;
    }

    const screenIds: string[] = dryRun.screen_ids;

    if (screenIds.length === 0) {
      window.alert("No screens would be affected.");
      return;
    }

    const prompt =
      `Delete evergreen content tied to expired alerts? ` +
      `This will affect ${screenIds.length} screens.`;

    if (!window.confirm(prompt)) return;

    const { status, error } = await fetch.post(API_PATH, {
      action: "alert_content_cleanup",
      screen_ids: screenIds,
    });

    window.alert(
      status === 200
        ? "Configuration updated."
        : `Error: Configuration update failed. ${error || ""}`,
    );
  };

  return (
    <section>
      <h3>Alert-Linked Config Cleanup </h3>
      <p>
        Delete evergreen content tied to alerts that are no longer present in
        the alerts feed.
      </p>
      <form
        onSubmit={async (event) => {
          event.preventDefault();
          if (isRunning) return;

          setIsRunning(true);
          try {
            await cleanupContent();
          } finally {
            setIsRunning(false);
          }
        }}
      >
        <button type="submit" disabled={isRunning}>
          Preview Cleanup
        </button>
      </form>
    </section>
  );
};

const UnusedAssetCleanup = () => {
  const [isRunning, setIsRunning] = useState(false);

  const cleanup = async () => {
    if (isRunning) return;
    setIsRunning(true);

    try {
      const preview = await fetch.post(API_PATH, {
        action: "unused_asset_cleanup",
        dry_run: true,
      });

      if (preview.status !== 200) {
        window.alert(
          `Error: ${preview.error || "Could not list unused assets."}`,
        );
        return;
      }

      const keys: string[] = preview.keys;
      if (keys.length === 0) {
        window.alert("No unused assets are eligible for deletion.");
        return;
      }

      if (
        !window.confirm(
          `Delete ${keys.length} unused assets from this environment's S3 storage? ` +
            "Only assets last modified more than 30 days ago are eligible. " +
            "This cannot be undone; deleted assets must be re-uploaded if needed.",
        )
      ) {
        return;
      }

      const result = await fetch.post(API_PATH, {
        action: "unused_asset_cleanup",
        keys,
      });

      window.alert(
        result.status === 200
          ? `Deleted ${result.deleted} unused assets.`
          : `Cleanup failed; some assets may already have been deleted. ${result.error || "Unknown error"}`,
      );
    } catch {
      window.alert(
        "Asset cleanup request failed. Check the connection and preview again before retrying.",
      );
    } finally {
      setIsRunning(false);
    }
  };

  return (
    <section>
      <h3>Unused Asset Cleanup</h3>
      <p>
        Delete image and video assets not referenced by any screen configuration
        in this environment. Assets uploaded or changed within the last 30
        days are kept, as are assets in each media folder&apos;s reusable/
        subfolder (for example, images/reusable/).
      </p>
      <p>
        Keep original custom assets in Figma, not S3. Deleted assets can be
        re-uploaded if needed from the Image Manager.
      </p>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          cleanup();
        }}
      >
        <button type="submit" disabled={isRunning}>
          Preview Cleanup
        </button>
      </form>
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
        `Overwrite all screen configurations and assets with the latest backup from ${environment}? ` +
          `\nConfigurations that don't exist in the backup will be deleted.`,
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

  const currentEnvironment = adminEnvironment();

  // Don't show the sync section in prod, since we never want to overwrite those configs.
  if (currentEnvironment === "prod") return null;

  return (
    <section>
      <h2>Sync Configurations from Source Environment</h2>
      <p>
        Replace all screen configurations in Postgres with the latest snapshot
        of the selected environment.
      </p>
      {currentEnvironment !== "local" && (
        <p>
          Image and audio assets from the source environment will also be copied
          over within S3.
        </p>
      )}
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
