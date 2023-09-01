import React, { ComponentType } from "react";

import EvergreenContent from "./evergreen_content";
import useIsOnScreen from "Hooks/v2/use_is_on_screen";
import { imagePath } from "Util/util";

const OutfrontEvergreenContent: ComponentType<{ asset_url: string }> = ({
  asset_url: assetUrl,
}) => {
  const dupReadyUrl = imagePath(assetUrl);
  const isPlaying = useIsOnScreen();
  return <EvergreenContent asset_url={dupReadyUrl} isPlaying={isPlaying} />;
};

export default OutfrontEvergreenContent;
