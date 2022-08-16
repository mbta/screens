import { isDup, isRealScreen } from "Util/util";
import { getDataset } from "Util/dataset";
// Previously tried @sentry/react and @sentry/browser as the SDK, but the QtWeb browser on e-inks could not 
// use them. Raven is an older stable SDK that better works with older browsers.
import Raven from "raven-js";

// https://docs.sentry.io/clients/javascript/usage/#raven-js-additional-context
type LogLevel = "info" | "warning" | "error";

const log = (message: string, level: LogLevel) => {
  Raven.captureMessage(message, {level});
};
const info = (message: string) => log(message, "info");
const warn = (message: string) => log(message, "warning");
const error = (message: string) => log(message, "error");

/**
 * Initializes Sentry if the DSN is defined and this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  const { sentry: sentryDsn, environmentName: env } = getDataset();

  // Note: passing an empty string as the DSN sets up a "no-op SDK" that captures errors and lets you call its methods,
  // but does not actually log anything to the Sentry service.

  if (sentryDsn && isRealScreen()) {
    Raven.config(sentryDsn, {environment: env}).install();
    if (isDup()) {
      const today = new Date()
      const hour = today.getHours()
      const min = today.getMinutes();
      if (hour === 8 && min >= 0 && min < 10) info(`Sentry intialized for app: ${appString}`)
    } else {
      info(`Sentry intialized for app: ${appString}`)
    }
  }
};

export default initSentry;
export {info, warn, error}
