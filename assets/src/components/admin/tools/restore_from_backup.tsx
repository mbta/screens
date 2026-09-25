import { useEffect, useRef, useState } from "react";
import ReactDiffViewer, { DiffMethod } from "react-diff-viewer-continued";
import { fetch } from "Util/admin";

const BACKUP_DATES_PATH = "/api/admin/backup_dates";
const DAILY_BACKUP_COMPARISON_PATH = "/api/admin/daily_backup_comparison";
const RESTORE_DAILY_BACKUP_PATH = "/api/admin/restore_daily_backup";

type ScreenConfigs = Record<string, unknown>;

// Prettify JSON for diff viewer display.
const formatJson = (value: ScreenConfigs) =>
  JSON.stringify(sortJson(value), null, 2);

// Sorts JSON objects recursively by their keys to ensure diff viewer has consistent ordering
const sortJson = (value: unknown): unknown => {
  if (Array.isArray(value)) return value.map(sortJson);

  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, nestedValue]) => [key, sortJson(nestedValue)]),
    );
  }

  return value;
};

// Since the loading indicator should only ever show very briefly, it is a static progress bar.
const DiffLoadingIndicator = ({ message }: { message: string }) => (
  <div className="daily-backup-diff__loading" role="status">
    <progress />
    <span>{message}</span>
  </div>
);

const DiffComputationLoadingIndicator = () => (
  <DiffLoadingIndicator message="Preparing configuration diff..." />
);

const RestoreFromBackup = () => {
  const [dates, setDates] = useState<string[]>([]);
  const [date, setDate] = useState("");
  const [currentConfigs, setCurrentConfigs] = useState<ScreenConfigs>({});
  const [backupConfigs, setBackupConfigs] = useState<ScreenConfigs>({});
  const [differingIds, setDifferingIds] = useState<string[]>([]);
  const [isLoadingComparison, setIsLoadingComparison] = useState(false);
  const [isRestoring, setIsRestoring] = useState(false);
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    fetch.get(BACKUP_DATES_PATH).then(({ dates }) => {
      setDates(dates);
    });
  }, []);

  const compare = async (backupDate: string) => {
    if (isLoadingComparison || backupDate === "") return;

    setDate(backupDate);
    setIsLoadingComparison(true);
    dialogRef.current?.showModal();

    const { status, current, backup, differing_ids, error } = await fetch.post(
      DAILY_BACKUP_COMPARISON_PATH,
      { date: backupDate },
    );

    setIsLoadingComparison(false);

    if (status === 200) {
      setCurrentConfigs(current);
      setBackupConfigs(backup);
      setDifferingIds(differing_ids);
    } else {
      closeDialog();
      window.alert(`Could not load comparison: ${error || "Unknown error"}`);
    }
  };

  const resetComparison = () => {
    setDate("");
    setCurrentConfigs({});
    setBackupConfigs({});
    setDifferingIds([]);
  };

  const closeDialog = () => dialogRef.current?.close();

  const restore = async () => {
    // Give user one last chance to confirm before we overwrite all configurations in Postgres with the backup.
    if (
      !window.confirm(
        `Overwrite all screen configurations with backup from ${date}?`,
      )
    ) {
      return;
    }

    if (isRestoring || date === "") return;

    setIsRestoring(true);
    const { status, upserted, deleted, error } = await fetch.post(
      RESTORE_DAILY_BACKUP_PATH,
      { date },
    );
    setIsRestoring(false);

    if (status === 200) {
      closeDialog();
      window.alert(`Restored ${upserted} configurations. Deleted ${deleted}.`);
    } else {
      window.alert(`Restore failed: ${error || "Unknown error"}`);
    }
  };

  return (
    <section>
      <h2>Restore from Daily Backup</h2>
      <p>Select one of this environment's daily configuration backups.</p>
      <select
        value={date}
        onChange={(event) => compare(event.target.value)}
        disabled={isLoadingComparison || isRestoring || dates.length === 0}
      >
        <option value="">
          {dates.length === 0
            ? "No daily backups available"
            : isLoadingComparison
              ? "Loading comparison..."
              : "Select a date"}
        </option>
        {dates.map((backupDate) => (
          <option key={backupDate} value={backupDate}>
            {backupDate}
          </option>
        ))}
      </select>
      <dialog
        className="daily-backup-diff"
        ref={dialogRef}
        onClose={resetComparison}
      >
        <header>
          <div>
            <h3>Restore configurations from {date}</h3>
            <p>
              Only configurations that differ are shown. Configurations missing
              from the backup will be deleted from Postgres.
            </p>
          </div>
          <button type="button" onClick={closeDialog} aria-label="Close">
            ×
          </button>
        </header>
        <div className="daily-backup-diff__viewer">
          {isLoadingComparison ? (
            <DiffLoadingIndicator message="Loading configurations..." />
          ) : (
            <>
              <div className="daily-backup-diff__screen-ids">
                <strong>Modified Screen IDs ({differingIds.length})</strong>
                <code>
                  {differingIds.length === 0 ? "None" : differingIds.join(", ")}
                </code>
              </div>
              <ReactDiffViewer
                oldValue={formatJson(currentConfigs)}
                newValue={formatJson(backupConfigs)}
                splitView
                compareMethod={DiffMethod.LINES}
                leftTitle="Current Live Configurations"
                rightTitle={`Backup Configurations (${date})`}
                showDiffOnly={false}
                highlightLanguage="json"
                loadingElement={DiffComputationLoadingIndicator}
                styles={{
                  titleBlock: {
                    minHeight: "48px",
                    padding: "14px 16px",
                    boxSizing: "border-box",
                    "& pre": {
                      margin: 0,
                      overflow: "visible",
                      fontSize: "14px",
                      fontWeight: 600,
                      lineHeight: 1.4,
                      whiteSpace: "normal",
                    },
                  },
                }}
              />
            </>
          )}
        </div>
        <footer>
          <button type="button" onClick={closeDialog} disabled={isRestoring}>
            Cancel
          </button>
          <button
            type="button"
            onClick={restore}
            disabled={isLoadingComparison || isRestoring}
          >
            {isRestoring ? "Restoring..." : `Restore ${date} backup`}
          </button>
        </footer>
      </dialog>
    </section>
  );
};

export default RestoreFromBackup;
