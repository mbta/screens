import DefaultNormalHeader from "Components/normal_header";
import { getScreenSide } from "Util/utils";

const NormalHeader = ({ icon, text, time }) => {
  let classModifier;
  const screenSide = getScreenSide();

  if (!screenSide) {
    classModifier = undefined;
  } else if (screenSide === "solo") {
    classModifier = "solo";
  } else {
    classModifier = "duo";
  }

  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      classModifier={classModifier}
    />
  );
};

export default NormalHeader;
