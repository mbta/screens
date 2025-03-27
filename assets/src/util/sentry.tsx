import { isDup } from "Util/outfront";
import { isRealScreen } from "Util/utils";
import { getDataset } from "Util/dataset";
// Previously tried @sentry/react and @sentry/browser as the SDK, but the QtWeb browser on e-inks could not
// use them. Raven is an older stable SDK that better works with older browsers.
import Raven, { RavenOptions, RavenTransportOptions } from "raven-js";

// https://docs.sentry.io/clients/javascript/usage/#raven-js-additional-context
type LogLevel = "info" | "warning" | "error";

const log = (message: string, level: LogLevel) => {
  Raven.captureMessage(message, { level });
};
const info = (message: string) => log(message, "info");
const warn = (message: string) => log(message, "warning");
const error = (message: string) => log(message, "error");

const captureException = (ex: unknown, options?: RavenOptions) => {
  Raven.captureException(ex, options);
};

const offline_events_key = "sentry_offline_events";

// Store offline Sentry events in localStorage for later retry
function cacheEvent(options: RavenTransportOptions) {
  try {
    const cached = localStorage.getItem(offline_events_key);
    const events = cached ? JSON.parse(cached) : [];
    events.push({
      ...options,
      data: {
        ...options.data,
        extra: {
          ...(options.data.extra || {}),
          cached: new Date().toISOString(),
        },
      },
    });
    localStorage.setItem(offline_events_key, JSON.stringify(events));
  } catch {}
}

function buildSentryAuthHeader(auth) {
  return `Sentry sentry_version=${auth.sentry_version}, sentry_client=${auth.sentry_client}, sentry_key=${auth.sentry_key}`;
}

function resendCachedEvents() {
  const cached = localStorage.getItem(offline_events_key);
  if (!cached) return;

  // Retry each event in the cache
  JSON.parse(cached).forEach((event: RavenTransportOptions) => {
    const headers = {
      "Content-Type": "application/json",
      "X-Sentry-Auth": buildSentryAuthHeader(event.auth),
    };

    fetch(event.url, {
      method: "POST",
      headers,
      body: JSON.stringify(event.data),
    });
  });

  localStorage.removeItem(offline_events_key);
}

function customTransport(options: RavenTransportOptions) {
  fetch(options.url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(options.data),
  }).catch(() => {
    // Cache the event only if the fetch was rejected, indicating that the network was likely unavailable
    cacheEvent(options);
  });
}

/**
 * Initializes Sentry if the DSN is defined AND this client is running on
 * a real production screen.
 */
const initSentry = (appString: string) => {
  const { sentry: sentryDsn, environmentName: env } = getDataset();

  if (sentryDsn && isRealScreen()) {
    Raven.setTransport(customTransport);
    Raven.config(sentryDsn, { environment: env }).install();

    // Set listener to retry any cached Sentry events any time the browser transitions from offline to online
    window.addEventListener("online", resendCachedEvents);

    if (isDup()) {
      const today = new Date();
      const hour = today.getHours();
      const min = today.getMinutes();
      if (hour === 8 && min >= 0 && min < 10)
        info(`Sentry intialized for app: ${appString}`);
    } else {
      info(`Sentry intialized for app: ${appString}`);
    }
  }
};

export default initSentry;
/** @knipignore */
export { info, warn, error, captureException };
