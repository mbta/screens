import React, { ComponentType, useEffect, useRef, useState } from "react";

interface Props {
  src: string;
  isPlaying: boolean;
  poster?: string;
}

/**
 * Wraps a `<video>` element in a component that starts playing the media as soon as both of the following are true:
 * - the element has fired the `canplay` event.
 * - the `isPlaying` prop is true
 *
 * Hardcoded attributes:
 * - `loop`: video loops indefinitely
 * - `playsInline`: video plays within the element, not fullscreen
 * - `muted`: any audio on the file is muted
 *
 * Playback can be paused by flipping `isPlaying` to false.
 *
 * An optional `poster` image url can be provided. This image will display before the video starts playing.
 * If a poster is not provided, the first frame of the video will display until it starts playing.
 */
const LoopingVideoPlayer: ComponentType<Props> = ({
  src,
  isPlaying,
  poster,
}) => {
  const ref = useRef(null as HTMLVideoElement | null);
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    if (isReady && ref?.current instanceof HTMLVideoElement) {
      if (isPlaying) {
        ref.current.play();
      } else {
        // It's ok to call this when the video hasn't started playing yet--it will have no effect.
        ref.current.pause();
      }
    }
  }, [isReady, isPlaying]);

  const handleCanPlay = () => {
    setIsReady(true);
  };

  return (
    <video
      src={src}
      className={"looping-video"}
      onCanPlay={handleCanPlay}
      ref={ref}
      poster={poster}
      loop
      playsInline
      muted
    />
  );
};

export default LoopingVideoPlayer;
