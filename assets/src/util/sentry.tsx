import * as Sentry from "@sentry/react";
import type { SeverityLevel } from "@sentry/react";

import { isOutfront } from "Util/outfront";
import { isRealScreen } from "Util/utils";
import { getDataset } from "Util/dataset";

const report = (
  level: SeverityLevel,
  message: string,
  extra?: Record<string, unknown>,
) => Sentry.captureMessage(message, { extra, level });

/**
 * Initializes Sentry if the DSN is defined AND this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  const { sentry: dsn, environmentName: environment } = getDataset();

  if (dsn && environment && isRealScreen()) {
    Sentry.init({
      dsn,
      environment,
      transport: Sentry.makeBrowserOfflineTransport(Sentry.makeFetchTransport),
      sendDefaultPii: true,
    });

    // Outfront devices load the page anew every time our content is displayed,
    // so they "initialize" very frequently compared to other screen hardware.
    // Limit these messages to a specific time of day so they don't exceed our
    // rate limit, but we still collect the browser/device data.
    if (isOutfront()) {
      const today = new Date();
      const hour = today.getHours();
      const min = today.getMinutes();
      if (hour === 8 && min >= 0 && min < 10)
        report("info", `Sentry initialized for app: ${appString}`);
    } else {
      report("info", `Sentry initialized for app: ${appString}`);
    }
  }
};

export default initSentry;
export { report };
