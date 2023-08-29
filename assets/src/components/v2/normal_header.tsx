import useTextResizer from "Hooks/v2/use_text_resizer";
import React, { forwardRef, ComponentType } from "react";
import { getDatasetValue } from "Util/dataset";

import LiveDataSvg from "../../../static/images/svgr_bundled/live-data-small.svg";

import {
  classWithModifier,
  classWithModifiers,
  formatTimeString,
  imagePath,
} from "Util/util";

enum Icon {
  green_b = "green_b",
  green_c = "green_c",
  green_d = "green_d",
  green_e = "green_e",
  logo = "logo",
  logo_negative = "logo_negative",
}

enum TitleSize {
  small = "small",
  large = "large",
}

const ICON_TO_SRC: Record<Icon, string> = {
  green_b: "GL-B.svg",
  green_c: "GL-C.svg",
  green_d: "GL-D.svg",
  green_e: "GL-E.svg",
  logo: "logo-white.svg",
  logo_negative: "logo-black.svg",
};

const abbreviateText = (text: string) => {
  if (text === "Government Center") {
    return "Government Ctr";
  }

  return text;
};

interface NormalHeaderIconProps {
  icon: Icon;
}

const NormalHeaderIcon: ComponentType<NormalHeaderIconProps> = ({ icon }) => {
  return (
    <div className="normal-header-icon">
      <img
        className="normal-header-icon__image"
        src={imagePath(ICON_TO_SRC[icon])}
      />
    </div>
  );
};

interface NormalHeaderTitleProps {
  icon?: Icon;
  text: string;
  size: TitleSize;
  showTo: boolean;
  fullName: boolean;
}

const NormalHeaderTitle: ComponentType<NormalHeaderTitleProps> = forwardRef(
  ({ icon, text, size, showTo, fullName }, ref) => {
    const modifiers: string[] = [size];
    if (icon) {
      modifiers.push("with-icon");
    } else {
      modifiers.push("no-icon");
    }

    const abbreviatedText = fullName ? text : abbreviateText(text);
    const environmentName = getDatasetValue("environmentName") || "";

    return (
      <>
        {["screens-dev", "screens-dev-green"].includes(environmentName) && (
          <div className="normal-header__environment">{environmentName}</div>
        )}
        <div className="normal-header-title">
          {icon && <NormalHeaderIcon icon={icon} />}
          <div
            className={classWithModifiers(
              "normal-header-title__text",
              modifiers,
            )}
            ref={ref}
          >
            {showTo && <div className="normal-header-to__text">TO</div>}
            {abbreviatedText}
          </div>
        </div>
      </>
    );
  },
);

interface NormalHeaderTimeProps {
  time: string;
}

export const NormalHeaderTime: ComponentType<NormalHeaderTimeProps> = ({
  time,
}) => {
  const currentTime = formatTimeString(time);
  return <div className="normal-header-time">{currentTime}</div>;
};

const NormalHeaderUpdated = () => {
  return (
    <div className="normal-header-updated">
      <LiveDataSvg
        color="white"
        width="25"
        height="25"
        viewBox="0 0 32 32"
        className="normal-header-updated__img"
      />
      <div className="normal-header-updated__text">
        UPDATED LIVE EVERY MINUTE
      </div>
    </div>
  );
};

interface NormalHeaderVersionProps {
  version: string;
}

const NormalHeaderVersion: ComponentType<NormalHeaderVersionProps> = ({
  version,
}) => {
  return <div className="normal-header-version">{version}</div>;
};

const NormalHeaderAccent = ({
  accentPatternFile,
}: {
  accentPatternFile: string;
}) => (
  <div className="normal-header__accent-pattern-container">
    <img
      className="normal-header__accent-pattern-image"
      src={imagePath(accentPatternFile)}
    />
  </div>
);

interface Props {
  icon?: Icon;
  text: string;
  time?: string;
  showUpdated?: boolean;
  version?: string;
  maxHeight: number;
  showTo?: boolean;
  fullName?: boolean;
  classModifiers?: string;
  accentPattern?: string;
}

const NormalHeader: ComponentType<Props> = ({
  icon,
  text,
  time,
  showUpdated = false,
  version,
  maxHeight,
  showTo = false,
  fullName = false,
  classModifiers,
  accentPattern,
}) => {
  const { ref: headerRef, size: headerSize } = useTextResizer({
    sizes: Object.keys(TitleSize),
    maxHeight: maxHeight,
    resetDependencies: [text],
  });
  return (
    <div className={classWithModifier("normal-header", classModifiers)}>
      <NormalHeaderTitle
        icon={icon}
        text={text}
        size={headerSize as TitleSize}
        ref={headerRef}
        showTo={showTo}
        fullName={fullName}
      />
      {time && <NormalHeaderTime time={time} />}
      {version && <NormalHeaderVersion version={version} />}
      {showUpdated && <NormalHeaderUpdated />}
      {accentPattern && (
        <NormalHeaderAccent accentPatternFile={accentPattern} />
      )}
    </div>
  );
};

export default NormalHeader;
export { Icon };
