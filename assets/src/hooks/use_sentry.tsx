import * as Sentry from "@sentry/react";

const useSentry = () => {
  const sentryDsn = document.getElementById("app")?.dataset.sentry;
  console.log(sentryDsn);
  if (sentryDsn) {
    Sentry.init({
      dsn: sentryDsn,
    });
  }
};

export default useSentry;
