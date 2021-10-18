import React, { useEffect } from "react";
import { ComponentType, useRef } from "react";

interface Props {
  text: string;
  volume: number;
}

const Audio: ComponentType<Props> = ({ text, volume = 1 }) => {
  const ref = useRef(null as HTMLAudioElement | null);

  useEffect(() => {
    fetchAudio("test");
  }, [text]);

  const fetchAudio = (text) => {
    try {
      fetch("/v2/audio/text_to_speech/" + text)
        .then((response) => response.blob())
        .then((blob) => {
          var url = URL.createObjectURL(blob);
          if (ref?.current instanceof HTMLAudioElement) {
            ref.current.src = url;
            ref.current.volume = volume;
            ref.current.play();
          }
        });
    } catch (err) {
      console.log(err);
    }
  };

  return (
    <div className="audio">
      <audio ref={ref} />
    </div>
  );
};

export default Audio;
