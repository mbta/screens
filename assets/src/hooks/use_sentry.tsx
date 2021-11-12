import * as Sentry from "@sentry/react";

const useSentry = () => {
  const sentryDsn = document.getElementById("app")?.dataset.sentry;
  if (sentryDsn) {
    Sentry.init({
      dsn: sentryDsn,
    });
  }
};

export default useSentry;
