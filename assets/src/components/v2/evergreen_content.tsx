import React, { ComponentType } from "react";

import LoopingVideoPlayer from "Components/v2/looping_video_player";

const IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "svg"];
const VIDEO_EXTENSIONS = ["mp4", "ogg"];

interface Props {
  asset_url: string;
}

const EvergreenContent: ComponentType<Props> = ({ asset_url: assetUrl }) => {
  const parts = assetUrl.split(".");
  const extension = parts[parts.length - 1].toLowerCase();

  if (IMAGE_EXTENSIONS.includes(extension)) {
    return <Image assetUrl={assetUrl} />;
  } else if (VIDEO_EXTENSIONS.includes(extension)) {
    return <Video assetUrl={assetUrl} />;
  }
  return null;
};

interface ProperProps {
  assetUrl: string;
}

const Image: ComponentType<ProperProps> = ({ assetUrl }) => {
  return (
    <div className="evergreen-content-image__container">
      <img className="evergreen-content-image__image" src={assetUrl} />
    </div>
  );
};

const Video: ComponentType<ProperProps> = ({ assetUrl }) => {
  return (
    <div className="evergreen-content-video">
      <LoopingVideoPlayer src={assetUrl} isPlaying />
    </div>
  );
};

export default EvergreenContent;
