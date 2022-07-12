import * as Sentry from "@sentry/react";
import { isRealScreen } from "Util/util";

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  const dataset = document.getElementById("app")?.dataset ?? {};
  const { sentry: sentryDsn, environmentName: env } = dataset;

  if (sentryDsn && isRealScreen()) {
    Sentry.init({
      dsn: sentryDsn,
      environment: env,
    });
    Sentry.captureMessage(`Sentry intialized for app: ${appString}`);
  }
};

export default initSentry;
