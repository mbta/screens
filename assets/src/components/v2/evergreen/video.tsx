import React, { ComponentType } from "react";

import LoopingVideoPlayer from "Components/v2/looping_video_player";

interface Props {
  videoUrl: string;
  posterUrl?: string;
}

const Video: ComponentType<Props> = ({ videoUrl, posterUrl }) => {
  return (
    <div className="evergreen-content-video">
      <LoopingVideoPlayer src={videoUrl} poster={posterUrl} isPlaying />
    </div>
  );
};

export default Video;
