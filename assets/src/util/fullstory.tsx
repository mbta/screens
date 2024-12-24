import { getDatasetValue } from "Util/dataset";
import * as FullStory from "@fullstory/browser";
import { isRealScreen } from "./utils";

/**
 * Initializes Fullstory if the org ID is defined
 * AND this client is running on a production screen simulation.
 */
const initFullstory = () => {
  const screenplayFullstoryOrgId = getDatasetValue("screenplayFullstoryOrgId");

  if (screenplayFullstoryOrgId && !isRealScreen()) {
    FullStory.init({
      orgId: screenplayFullstoryOrgId,
      recordCrossDomainIFrames: true,
    });
  }
};

export default initFullstory;
