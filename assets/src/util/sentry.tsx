import * as Sentry from "@sentry/react";
import { isRealScreen } from "Util/util";

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  try {
    const dataset = document.getElementById("app")?.dataset ?? {};
    const { sentry: sentryDsn, environmentName: env } = dataset;

    // Note: passing an empty string as the DSN sets up a "no-op SDK" that captures errors and lets you call its methods,
    // but does not actually log anything to the Sentry service.
    if (sentryDsn && isRealScreen()) {
      Sentry.init({
        dsn: sentryDsn,
        environment: env,
      });
      Sentry.captureMessage(`Sentry intialized for app: ${appString}`);
    }
  } catch (e) {
    const failureLogUrl = new URL("/debug/log_sentry_init_failure", window.location.href);
    failureLogUrl.searchParams.set("app_id", appString);
    if (e instanceof Error) {
      failureLogUrl.searchParams.set("message", e.message);
    } else if (typeof e == "string") {
      failureLogUrl.searchParams.set("message", e);
    } else {
      failureLogUrl.searchParams.set("message", JSON.stringify(e));
    }

    fetch(failureLogUrl);
  }
};

export default initSentry;
