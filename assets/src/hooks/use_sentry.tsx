import * as Sentry from "@sentry/react";
import { useEffect } from "react";
import { useLocation } from "react-router-dom";
import { isDup } from "Util/util";

const useSentry = () => {
  const sentryDsn = document.getElementById("app")?.dataset.sentry;
  const env = document.getElementById("app")?.dataset.environmentName;
  const isRealScreen = isDup() || new URLSearchParams(useLocation().search).get("is_real_screen");
  useEffect(() => {
    if (sentryDsn && isRealScreen) {
      Sentry.init({
        dsn: sentryDsn,
        environment: env,
      });
    }
  }, [sentryDsn]);
};

export default useSentry;
