import type { ComponentType } from "react";
import { extensionForAsset } from "Util/utils";

const IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "svg", "gif", "webp"];

interface Props {
  asset_url: string;
  header_text: string;
}

const Wayfinding: ComponentType<Props> = ({
  asset_url: assetUrl,
  header_text: headerText,
}) => {
  if (IMAGE_EXTENSIONS.includes(extensionForAsset(assetUrl))) {
    return (
      <div className="wayfinding-container">
        {headerText && (
          <header className="wayfinding-header">
            <span>{headerText}</span>
          </header>
        )}
        <img className="wayfinding-image" src={assetUrl} />
      </div>
    );
  } else {
    return null;
  }
};

export default Wayfinding;
