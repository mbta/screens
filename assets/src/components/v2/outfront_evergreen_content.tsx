import React, { ComponentType } from "react";

import EvergreenContent from "./evergreen_content";
import useIsOnScreen from "Hooks/v2/use_is_on_screen";
import { imagePath } from "Util/util";
import { TRIPTYCH_VERSION } from "./triptych/version";
import { usePlayerName } from "Hooks/outfront";
import { isOFM } from "Util/outfront";

if (isOFM()) {
  require.context("../../../static/images/triptych_psas", true, /\.(webp)$/);
}

const OutfrontEvergreenContent: ComponentType<{
  asset_url: string;
  show_identifiers: boolean;
}> = ({ asset_url: assetUrl, show_identifiers: showIdentifiers }) => {
  const dupReadyUrl = imagePath(assetUrl);
  const isPlaying = useIsOnScreen();
  const playerName = usePlayerName();
  const identifiers = `${TRIPTYCH_VERSION} ${playerName ? playerName : ""}`;
  return (
    <>
      <EvergreenContent asset_url={dupReadyUrl} isPlaying={isPlaying} />
      {showIdentifiers && (
        <div className="evergreen-content__identifiers">{identifiers}</div>
      )}
    </>
  );
};

export default OutfrontEvergreenContent;
