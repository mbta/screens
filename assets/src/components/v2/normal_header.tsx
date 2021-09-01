import React, {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";

import { classWithModifiers, formatTimeString, imagePath } from "Util/util";

const ICON_TO_SRC = {
  green_b: "GL-B.svg",
  green_c: "GL-C.svg",
  green_d: "GL-D.svg",
  green_e: "GL-E.svg",
  logo: "logo-white.svg",
};

const NormalHeaderIcon = ({ icon }) => {
  return (
    <div className="normal-header-icon">
      <img
        className="normal-header-icon__image"
        src={imagePath(ICON_TO_SRC[icon])}
      />
    </div>
  );
};

const NormalHeaderTitle = forwardRef(({ icon, text, size }, ref) => {
  const modifiers = [size];
  if (icon) {
    modifiers.push("with-icon");
  }

  return (
    <div className="normal-header-title">
      {icon && <NormalHeaderIcon icon={icon} />}
      <div
        className={classWithModifiers("normal-header-title__text", modifiers)}
        ref={ref}
      >
        {text}
      </div>
    </div>
  );
});

const NormalHeaderTime = ({ time }) => {
  const currentTime = formatTimeString(time);
  return <div className="normal-header-time">{currentTime}</div>;
};

const NormalHeaderUpdated = () => {
  return (
    <div className="normal-header-updated">
      <div className="normal-header-updated__icon">
        <img
          className="normal-header-updated__img"
          src={imagePath("live-data-small.svg")}
        />
      </div>
      <div className="normal-header-updated__text">
        UPDATED LIVE EVERY MINUTE
      </div>
    </div>
  );
};

const NormalHeaderVersion = ({ versionNumber }) => {
  return <div className="normal-header-version">{versionNumber}</div>;
};

const NormalHeader = ({
  icon,
  text,
  time,
  showUpdated,
  versionNumber,
  maxHeight,
}) => {
  const SIZES = ["small", "large"];
  const ref = useRef(null);
  const [stopSize, setStopSize] = useState(1);

  // Reset state when relevant props change,
  // so that we recalculate size from scratch.
  useEffect(() => {
    setStopSize(1);
  }, [icon, text]);

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > maxHeight) {
      setStopSize(stopSize - 1);
    }
  });

  return (
    <div className="normal-header">
      <NormalHeaderTitle
        icon={icon}
        text={text}
        size={SIZES[stopSize]}
        ref={ref}
      />
      <NormalHeaderTime time={time} />
      {versionNumber && <NormalHeaderVersion versionNumber={versionNumber} />}
      {showUpdated && <NormalHeaderUpdated />}
    </div>
  );
};

export default NormalHeader;
