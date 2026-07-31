import LinkArrow from "../bundled_svg/link_arrow";
import FreeText, { FreeTextType } from "Components/free_text";

import NormalHeader from "./normal_header";

interface TakeoverAlertProps {
  text: FreeTextType;
  remedy: FreeTextType;
  header: {
    text: string;
    color: string;
  };
  link_text?: string;
}

const TakeoverAlert = (alert: TakeoverAlertProps) => {
  const { text, remedy, header, link_text: linkText } = alert;

  return (
    <>
      <NormalHeader
        text={header.text}
        color={header.color}
        accentPattern="dup-accent-pattern.svg"
      />
      <div className="full-screen-alert__body">
        <div className="full-screen-alert__body-text">
          <FreeText lines={remedy ? [text, remedy] : [text]}></FreeText>
        </div>
        <div className="full-screen-alert__link">
          <div className="full-screen-alert__link-arrow">
            <LinkArrow width={628} colorHex="#64696e" />
          </div>
          <div className="full-screen-alert__link-text">
            {linkText ? linkText : "mbta.com/alerts"}
          </div>
        </div>
      </div>
    </>
  );
};

export default TakeoverAlert;
