// import * as Sentry from "@sentry/react";
import { isRealScreen } from "Util/util";
// import * as Sentry from "@sentry/browser";
import Raven from "raven-js";

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  // const dataset = document.getElementById("app")?.dataset ?? {};
  // const { sentry: sentryDsn, environmentName: env } = dataset;

  // Note: passing an empty string as the DSN sets up a "no-op SDK" that captures errors and lets you call its methods,
  // but does not actually log anything to the Sentry service.
  // Raven.init({
  //   dsn: sentryDsn && isRealScreen() ? sentryDsn : "",
  //   environment: env,
  // });

  if (isRealScreen()) {
    Raven.config("https://45a59d5eb11a418f857e838eb4d6e73d@o89189.ingest.sentry.io/6061747").install();
    Raven.captureMessage(`Sentry intialized for app: ${appString}`);
  }

};

export default initSentry;
