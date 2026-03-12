import { init } from "@fullstory/browser";
import { getDatasetValue } from "Util/dataset";
import { isRealScreen } from "./utils";

/**
 * Initializes Fullstory if the org ID is defined
 * AND this client is running on a production screen simulation.
 */
const initFullstory = () => {
  const orgId = getDatasetValue("screenplayFullstoryOrgId");

  if (orgId && !isRealScreen()) {
    init({ orgId, recordCrossDomainIFrames: true });
  }
};

export default initFullstory;
