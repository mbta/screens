import * as Sentry from "@sentry/react";
import { useEffect } from "react";
import { useLocation } from "react-router-dom";

const useSentry = () => {
  const sentryDsn = document.getElementById("app")?.dataset.sentry;
  const query = new URLSearchParams(useLocation().search);
  const isRealScreen = query.get("is_real_screen");
  useEffect(() => {
    if (sentryDsn && isRealScreen) {
      Sentry.init({
        dsn: sentryDsn,
      });
    }
  }, [sentryDsn]);
};

export default useSentry;
