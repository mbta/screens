import React, { useMemo, useState } from "react";
import { fetch } from "Util/admin";

const API_PATH = "/api/admin/maintenance";

const MaintenanceTools = () => {
  return (
    <main>
      <EvergreenContentCleanup />
    </main>
  );
};

const EvergreenContentCleanup = () => {
  const today = useMemo(() => new Date().toISOString().split("T")[0], []);
  const [contentCleanupDate, setContentCleanupDate] = useState(today);

  const cleanupContent = async () => {
    const prompt = `Delete evergreen content prior to ${contentCleanupDate}?`;

    if (window.confirm(prompt)) {
      await fetch.post(API_PATH, {
        action: "content_cleanup",
        before: contentCleanupDate,
      });
    }
  };

  return (
    <section>
      <h2>Evergreen Content Cleanup</h2>
      <p>
        Evergreen content that is scheduled entirely before the specified date
        will be deleted.
      </p>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          cleanupContent();
        }}
      >
        <input
          type="date"
          value={contentCleanupDate}
          onChange={(event) => setContentCleanupDate(event.target.value)}
        />
        <button type="submit">Cleanup</button>
      </form>
    </section>
  );
};

export default MaintenanceTools;
