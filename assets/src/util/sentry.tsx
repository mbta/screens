import * as Sentry from "@sentry/react";
import { isRealScreen } from "Util/util";
import { getDataset } from "Util/dataset";

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  const { sentry: sentryDsn, environmentName: env } = getDataset();

  if (sentryDsn && isRealScreen()) {
    Sentry.init({
      dsn: sentryDsn,
      environment: env,
    });
    Sentry.captureMessage(`Sentry intialized for app: ${appString}`);
  }
};

export default initSentry;
