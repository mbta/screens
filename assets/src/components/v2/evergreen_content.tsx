import React, { ComponentType } from "react";

import LoopingVideoPlayer from "Components/v2/looping_video_player";

const IMAGE_EXTENSIONS = ["png", "jpg", "jpeg"];
const VIDEO_EXTENSIONS = ["mp4", "ogg"];

interface Props {
  assetUrl: string;
}

const EvergreenContent: ComponentType<Props> = ({ assetUrl }) => {
  const parts = assetUrl.split(".");
  const extension = parts[parts.length - 1].toLowerCase();

  if (IMAGE_EXTENSIONS.includes(extension)) {
    return <Image assetUrl={assetUrl} />;
  } else if (VIDEO_EXTENSIONS.includes(extension)) {
    return <Video assetUrl={assetUrl} />;
  }
  return null;
};

const Image: ComponentType<Props> = ({ assetUrl }) => {
  return (
    <div className="evergreen-content-image__container">
      <img className="evergreen-content-image__image" src={assetUrl} />
    </div>
  );
};

const Video: ComponentType<Props> = ({ assetUrl }) => {
  return (
    <div className="evergreen-content-video">
      <LoopingVideoPlayer src={assetUrl} isPlaying />
    </div>
  );
};

export default EvergreenContent;
