import { useEffect } from "react";

/**
 * Defines a protocol the "Inspector" admin UI can use to communicate with
 * iframe'd screens. Limit usage of these functions to this specific purpose;
 * components _within_ a screen have many better options (props, contexts, etc.)
 * for communicating with each other.
 */

export type Message =
  | { type: "data_refreshed"; timestamp: number }
  | { type: "refresh_data" }
  | { type: "set_refresh_rate"; ms: number | null };

const sendMessage = (window: Window, message: Message) =>
  window.postMessage(message, { targetOrigin: location.origin });

const useReceiveMessage = (handler: (message: Message) => void) =>
  useEffect(() => {
    const listener = ({ data, origin }) =>
      origin == location.origin && handler(data);

    window.addEventListener("message", listener);
    return () => window.removeEventListener("message", listener);
  });

export { sendMessage, useReceiveMessage };
