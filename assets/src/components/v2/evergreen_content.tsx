import React, { ComponentType } from "react";

import LoopingVideoPlayer from "Components/v2/looping_video_player";

const IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "svg", "gif", "webp"];
const VIDEO_EXTENSIONS = ["mp4", "ogg", "ogv", "webm"];

interface Props {
  asset_url: string;
  isPlaying?: boolean;
}

const EvergreenContent: ComponentType<Props> = ({
  asset_url: assetUrl,
  isPlaying = true,
}) => {
  const parts = assetUrl.split(".");
  const extension = parts[parts.length - 1].toLowerCase();

  if (IMAGE_EXTENSIONS.includes(extension)) {
    return <Image assetUrl={assetUrl} />;
  } else if (VIDEO_EXTENSIONS.includes(extension)) {
    return <Video assetUrl={assetUrl} isPlaying={isPlaying} />;
  }
  return null;
};

const Image: ComponentType<{ assetUrl: string }> = ({ assetUrl }) => {
  return (
    <div className="evergreen-content-image__container">
      <img className="evergreen-content-image__image" src={assetUrl} />
    </div>
  );
};

interface VideoProps {
  assetUrl: string;
  isPlaying: boolean;
}

const Video: ComponentType<VideoProps> = ({ assetUrl, isPlaying }) => {
  return (
    <div className="evergreen-content-video">
      <LoopingVideoPlayer src={assetUrl} isPlaying={isPlaying} />
    </div>
  );
};

export default EvergreenContent;
