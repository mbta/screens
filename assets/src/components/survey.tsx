import type { ComponentType } from "react";
import EvergreenContent from "Components/evergreen_content";

interface Props {
  medium_asset_url: string;
  large_asset_url: string;
}

const Survey: ComponentType<Props> = ({
  medium_asset_url: mediumAssetUrl,
  large_asset_url: largeAssetUrl,
}) => {
  return (
    <div className="survey__container">
      <div className="survey__medium">
        <EvergreenContent asset_url={mediumAssetUrl} />
      </div>
      <div className="survey__large">
        <EvergreenContent asset_url={largeAssetUrl} />
      </div>
    </div>
  );
};

export default Survey;
