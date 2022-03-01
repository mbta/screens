import React, { ComponentType, useState, useEffect } from "react";

interface Props {
  asset_urls: string[];
}

const intervalInMs = 10000

const FullLineMap: ComponentType<Props> = ({asset_urls}) => {
  const [assetIndex, setAssetIndex] = useState(0);

  useEffect(() => {
  if (assetIndex === asset_urls.length - 1) {
    setTimeout(() => {setAssetIndex(0)}, intervalInMs)
  } else {
    setTimeout(() => {setAssetIndex((i) => i + 1)}, intervalInMs)
  }
}, [assetIndex])

  return <Image assetUrl={asset_urls[assetIndex]} />;
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