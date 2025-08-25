import * as Sentry from "@sentry/react";
import type { SeverityLevel } from "@sentry/react";

import { isDup } from "Util/outfront";
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

    if (isDup()) {
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
