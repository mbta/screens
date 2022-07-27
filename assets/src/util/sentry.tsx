import * as Sentry from "@sentry/react";
import { isRealScreen } from "Util/util";

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  const dataset = document.getElementById("app")?.dataset ?? {};
  const { sentry: sentryDsn, environmentName: env } = dataset;

  // Note: passing an empty string as the DSN sets up a "no-op SDK" that captures errors and lets you call its methods,
  // but does not actually log anything to the Sentry service.
  Sentry.init({
    dsn: sentryDsn && isRealScreen() ? sentryDsn : "",
    environment: env,
  });

  Sentry.captureMessage(`Sentry intialized for app: ${appString}`);

};

export default initSentry;
