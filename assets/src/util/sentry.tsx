import * as Sentry from "@sentry/react";
import { isRealScreen } from "Util/util";

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = () => {
  console.log("called initSentry");

  const dataset = document.getElementById("app")?.dataset ?? {};
  const { sentry: sentryDsn, environmentName: env } = dataset;

  console.log("sentryDsn =", sentryDsn);
  console.log("env =", env);

  if (sentryDsn && isRealScreen()) {
    console.log("starting Sentry");
    Sentry.init({
      dsn: sentryDsn,
      environment: env,
    });
  }
};

export default initSentry;
