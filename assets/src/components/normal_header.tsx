import { type ComponentType } from "react";

import useAutoSize from "Hooks/use_auto_size";
import LiveDataSvg from "Images/live-data-small.svg";
import { getDatasetValue } from "Util/dataset";
import { classWithModifiers, formatTimeString, imagePath } from "Util/utils";

enum Icon {
  green_b = "green_b",
  green_c = "green_c",
  green_d = "green_d",
  green_e = "green_e",
  logo = "logo",
  logo_negative = "logo_negative",
}

const ICON_TO_SRC: Record<Icon, string> = {
  green_b: "GL-B.svg",
  green_c: "GL-C.svg",
  green_d: "GL-D.svg",
  green_e: "GL-E.svg",
  logo: "logo-white.svg",
  logo_negative: "logo-black.svg",
};

// When the header text is a stop name consisting of two street names with a
// separator like "@" between them, if the text has to wrap, we prefer the line
// break to fall immediately before or after the separator. Define a pattern to
// look for this and some possible replacements.
const BREAK_PATTERN = / (@|opp) /;
const BREAK_AFTER = " $1\n";
const BREAK_BEFORE = "\n$1 ";
const BREAK_NONE = "$&";

const SIZING_RULES = {
  largeAfter: { classes: ["large"], replacement: BREAK_AFTER },
  largeBefore: { classes: ["large"], replacement: BREAK_BEFORE },
  largeWrap: { classes: ["large", "wrap"], replacement: BREAK_NONE },
  smallAfter: { classes: ["small"], replacement: BREAK_AFTER },
  smallBefore: { classes: ["small"], replacement: BREAK_BEFORE },
  smallWrap: { classes: ["small", "wrap"], replacement: BREAK_NONE },
};

const sizingSteps = (text: string): (keyof typeof SIZING_RULES)[] =>
  BREAK_PATTERN.test(text)
    ? [
        "largeAfter",
        "largeBefore",
        // Intentionally omit largeWrap so we prefer reducing the text size over
        // allowing an "awkward" line break.
        "smallAfter",
        "smallBefore",
        "smallWrap",
      ]
    : ["largeWrap", "smallWrap"];

interface NormalHeaderTitleProps {
  icon?: Icon;
  text: string;
  showTo: boolean;
}

const NormalHeaderTitle: ComponentType<NormalHeaderTitleProps> = ({
  icon,
  text,
  showTo,
}) => {
  const environmentName = getDatasetValue("environmentName") || "";
  const { ref, step } = useAutoSize(sizingSteps(text), text);
  const { classes, replacement } = SIZING_RULES[step];

  return (
    <>
      {["screens-dev", "screens-dev-green"].includes(environmentName) && (
        <div className="normal-header__environment">{environmentName}</div>
      )}
      <div
        className={classWithModifiers("normal-header-title", [
          ...classes,
          icon ? "with-icon" : "no-icon",
        ])}
        ref={ref}
      >
        {icon && (
          <img
            className="normal-header-title__icon"
            src={imagePath(ICON_TO_SRC[icon])}
          />
        )}
        <div className="normal-header-title__text">
          {showTo && <div className="normal-header-to__text">TO</div>}
          {text.replace(BREAK_PATTERN, replacement)}
        </div>
      </div>
    </>
  );
};

interface NormalHeaderTimeProps {
  time: string;
}

const NormalHeaderTime: ComponentType<NormalHeaderTimeProps> = ({ time }) => {
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
  showTo?: boolean;
  classModifier?: string;
  accentPattern?: string;
  variant?: string | null;
}

const NormalHeader: ComponentType<Props> = ({
  icon,
  text,
  time,
  showUpdated = false,
  version,
  showTo = false,
  classModifier,
  accentPattern,
  variant,
}) => {
  return (
    <div
      className={classWithModifiers("normal-header", [classModifier, variant])}
    >
      <NormalHeaderTitle icon={icon} text={text} showTo={showTo} />
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
