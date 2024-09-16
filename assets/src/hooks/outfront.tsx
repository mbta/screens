import { useMemo } from "react";
import { getMRAID, getPlayerName, getStationName } from "Util/outfront";

/**
 * Returns the player name, or null if we fail to determine it for any reason.
 */
export const usePlayerName = (): string | null =>
  useMemo(getPlayerName, [getMRAID()]);

/**
 * Returns the station name, or null if we fail to determine it for any reason.
 */
export const useStationName = (): string | null =>
  useMemo(getStationName, [getMRAID()]);
