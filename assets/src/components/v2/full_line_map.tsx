import makePersistentCarousel, { PageRendererProps } from "Components/v2/persistent_carousel";
import React, { ComponentType } from "react";

interface Page {
  asset_url: string;
}

type Props = PageRendererProps<Page>;

const FullLineMapImagePage: ComponentType<Props> = ({ page: { asset_url: assetUrl } }) => {
  return (
    <div className="full-line-map-image__container">
      <img className="full-line-map-image__image" src={assetUrl} />
    </div>
  );
};

export default makePersistentCarousel(FullLineMapImagePage);
