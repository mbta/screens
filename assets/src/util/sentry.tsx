import { isRealScreen } from "Util/util";
import Raven from "raven-js";

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  const dataset = document.getElementById("app")?.dataset ?? {};
  const { sentry: sentryDsn, environmentName: env } = dataset;

  // Note: passing an empty string as the DSN sets up a "no-op SDK" that captures errors and lets you call its methods,
  // but does not actually log anything to the Sentry service.

  if (sentryDsn && isRealScreen()) {
    Raven.config(sentryDsn, {environment: env}).install();
    Raven.captureMessage(`Sentry intialized for app: ${appString}`, {level: "info"});
  }
};

export default initSentry;
