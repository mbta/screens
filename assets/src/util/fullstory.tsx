import { getDatasetValue } from "Util/dataset";
import * as FullStory from "@fullstory/browser";
import { isRealScreen } from "./util";

/**
 * Initializes Sentry if the DSN is defined AND this client is running on
 * a real production screen AND the URL does not contain the disable_sentry param.
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
