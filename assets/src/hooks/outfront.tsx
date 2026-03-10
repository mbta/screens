import { useMemo } from "react";
import { getPlayerName, getStationName } from "Util/outfront";

/**
 * Returns the player name, or null if we fail to determine it for any reason.
 */
export const usePlayerName = (): string | null =>
  useMemo(() => getPlayerName(), []);

/**
 * Returns the station name, or null if we fail to determine it for any reason.
 */
export const useStationName = (): string | null =>
  useMemo(() => getStationName(), []);
