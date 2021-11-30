import * as Sentry from "@sentry/react";
import { useEffect } from "react";

const useSentry = () => {
  const sentryDsn = document.getElementById("app")?.dataset.sentry;
  useEffect(() => {
    if (sentryDsn) {
      Sentry.init({
        dsn: sentryDsn,
      });
    }
  }, [sentryDsn]);
};

export default useSentry;
