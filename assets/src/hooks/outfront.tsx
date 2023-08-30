import { useMemo } from "react";
import {
  getMRAID,
  getPlayerName,
  getStationName,
  getTriptychPane,
} from "Util/outfront";
import type { TriptychPane } from "Util/outfront";

/**
 * Returns the player name, or null if we fail to determine it for any reason.
 */
export const usePlayerName = (): string | null =>
  useMemo(getPlayerName, [getMRAID()]);

/**
 * Returns the triptych pane, or null if we fail to determine it for any reason.
 */
export const useTriptychPane = (): TriptychPane | null =>
  useMemo(getTriptychPane, [getMRAID()]);

/**
 * Returns the station name, or null if we fail to determine it for any reason.
 */
export const useStationName = (): string | null =>
  useMemo(getStationName, [getMRAID()]);
