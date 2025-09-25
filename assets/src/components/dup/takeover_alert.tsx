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
}

const TakeoverAlert = (alert: TakeoverAlertProps) => {
  const { text, remedy, header } = alert;

  return (
    <>
      <NormalHeader
        text={header.text}
        color={header.color}
        accentPattern="dup-accent-pattern.svg"
      />
      <div className="full-screen-alert__body">
        <div className="full-screen-alert__body-text">
          <FreeText lines={[text, remedy]} />
        </div>
        <div className="full-screen-alert__link">
          <div className="full-screen-alert__link-arrow">
            <LinkArrow width={628} colorHex="#64696e" />
          </div>
          <div className="full-screen-alert__link-text">mbta.com/alerts</div>
        </div>
      </div>
    </>
  );
};

export default TakeoverAlert;
