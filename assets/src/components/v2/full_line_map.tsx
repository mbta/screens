import React, { ComponentType } from "react";

interface Props {
  asset_url: string;
}

const FullLineMap: ComponentType<Props> = ({ asset_url: assetUrl }) => {
  return <Image assetUrl={assetUrl} />;
}

interface ProperProps {
  assetUrl: string;
}

const Image: ComponentType<ProperProps> = ({ assetUrl }) => {
  return (
    <div className="full-line-map-image__container">
      <img className="full-line-map-image__image" src={assetUrl} />
    </div>
  );
};

export default FullLineMap;