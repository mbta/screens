import { isDup } from "Util/outfront";
import { isRealScreen } from "Util/utils";
import { getDataset } from "Util/dataset";
// Previously tried @sentry/react and @sentry/browser as the SDK, but the QtWeb browser on e-inks could not
// use them. Raven is an older stable SDK that better works with older browsers.
import Raven, { RavenOptions, RavenTransportOptions } from "raven-js";

// https://docs.sentry.io/clients/javascript/usage/#raven-js-additional-context
type LogLevel = "info" | "warning" | "error";

const log = (message: string, level: LogLevel, extra?: any) => {
  const options: RavenOptions = { level };
  if (extra) {
    options.extra = extra;
  }
  Raven.captureMessage(message, options);
};
const info = (message: string, extra?: any) => log(message, "info", extra);
const warn = (message: string, extra?: any) => log(message, "warning", extra);
const error = (message: string, extra?: any) => log(message, "error", extra);

const captureException = (ex: unknown, options?: RavenOptions) => {
  Raven.captureException(ex, options);
};

const OFFLINE_EVENTS_KEY = "sentry_offline_events";

// Store offline Sentry events in localStorage for later retry
function cacheEvent(options: RavenTransportOptions) {
  try {
    const cached = localStorage.getItem(OFFLINE_EVENTS_KEY);
    const events = cached ? JSON.parse(cached) : [];

    // Remove oldest event if limit is reached
    if (events.length >= 30) {
      events.shift();
    }

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
    localStorage.setItem(OFFLINE_EVENTS_KEY, JSON.stringify(events));
  } catch {}
}

function buildSentryAuthHeader(auth) {
  return `Sentry sentry_version=${auth.sentry_version}, sentry_client=${auth.sentry_client}, sentry_key=${auth.sentry_key}`;
}

async function resendCachedEvents() {
  const cached = localStorage.getItem(OFFLINE_EVENTS_KEY);
  if (!cached) return;

  const events = JSON.parse(cached);

  for (let i = 0; i < events.length; i++) {
    try {
      const event = events[i];
      const response = await fetch(event.url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Sentry-Auth": buildSentryAuthHeader(event.auth),
        },
        body: JSON.stringify(event.data),
      });

      if (response.ok) {
        events.splice(i, 1);
        i--;
      }
    } catch {}
  }

  localStorage.setItem(OFFLINE_EVENTS_KEY, JSON.stringify(events));
}

// Once we are no longer bounded by browser constraints (old bus-eink),
// we can migrate off of Raven to @sentry/browser and use their built-in offline caching.
// Documentation for reference: https://docs.sentry.io/platforms/javascript/guides/react/best-practices/offline-caching/
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
    // 5 minute interval for retries in case "online" event never fires
    setInterval(resendCachedEvents, 5 * 60 * 1000);

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
