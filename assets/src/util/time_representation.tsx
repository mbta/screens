export type TimeRepresentation =
  | { type: "text"; text: string }
  | { type: "minutes"; minutes: number }
  | { type: "timestamp"; timestamp: string; ampm: string };
