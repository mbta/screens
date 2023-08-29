import { useMemo } from "react";
import {
  getMRAID,
  getPlayerName,
  getStationName,
  getTriptychPane,
} from "Util/outfront";
import type { TriptychPane } from "Util/outfront";

export const usePlayerName = (): string | null =>
  useMemo(getPlayerName, [getMRAID()]);

export const useTriptychPane = (): TriptychPane | null =>
  useMemo(getTriptychPane, [getMRAID()]);

export const useStationName = (): string | null =>
  useMemo(getStationName, [getMRAID()]);
