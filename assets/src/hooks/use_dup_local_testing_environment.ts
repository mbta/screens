import { useMemo } from "react";
import { __TEST_setFakeMRAID__ } from "Util/outfront";

const DEFAULT_PLAYER_NAME = "BKB-DUP-TEST";
const DEFAULT_STATION = "Back Bay";

// Query param keys
const IS_TEST_KEY = "test";
const PLAYER_NAME_KEY = "playerName";
const STATION_NAME_KEY = "station";

/**
 * If any of the specified query params are provided in the URL,
 * we are testing in a local environment and explicitly set
 * a fake MRAID object to test as if running on a real DUP screen.
 */
export const useDupLocalTestingEnvironment = () =>
  useMemo(() => {
    const queryParams = new URLSearchParams(window.location.search);

    const isLocalTest = queryParams.get(IS_TEST_KEY);
    const playerName = queryParams.get(PLAYER_NAME_KEY);
    const station = queryParams.get(STATION_NAME_KEY);

    if (isLocalTest !== null || playerName || station) {
      __TEST_setFakeMRAID__({
        playerName: playerName ? playerName : DEFAULT_PLAYER_NAME,
        station: station ? station : DEFAULT_STATION,
      });
    }
  }, []);
