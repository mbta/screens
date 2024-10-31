import { useEffect } from "react";
import { type AudioConfig } from "Components/v2/screen_container";

/**
 * Defines a protocol the "Inspector" admin UI can use to communicate with
 * iframe'd screens. Limit usage of these functions to this specific purpose;
 * components _within_ a screen have many better options (props, contexts, etc.)
 * for communicating with each other.
 *
 * In screen code, use ONLY the `toInspector`/`fromInspector` functions. These
 * safely do nothing if the screen is not running within the inspector.
 */

export type Message =
  | { type: "audio_config"; config: AudioConfig | null }
  | { type: "data_refreshed"; timestamp: number }
  | { type: "refresh_data" }
  | { type: "set_data_variant"; variant: string | null }
  | { type: "set_refresh_rate"; ms: number | null };

export const INSPECTOR_FRAME_NAME = "screen-inspector-frame";

const isFramed = (): boolean => window.name == INSPECTOR_FRAME_NAME;

const sendMessage = (window: Window, message: Message) =>
  window.postMessage(message, { targetOrigin: location.origin });

const sendToInspector = (message: Message) => {
  if (isFramed()) sendMessage(window.parent, message);
};

type MessageHandler = (message: Message) => void;

const useReceiveMessage = (handler: MessageHandler) =>
  useEffect(() => receiveHook(handler));

const useReceiveFromInspector = (handler: MessageHandler) =>
  useEffect(() => (isFramed() ? receiveHook(handler) : undefined));

const receiveHook = (handler: MessageHandler) => {
  const listener = ({ data, origin }) =>
    origin == location.origin && handler(data);

  window.addEventListener("message", listener);
  return () => window.removeEventListener("message", listener);
};

export {
  isFramed,
  sendMessage,
  sendToInspector,
  useReceiveMessage,
  useReceiveFromInspector,
};
