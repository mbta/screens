import { classWithModifier } from "Util/utils";
import FreeText, { FreeTextType } from "Components/free_text";
import NormalHeader from "./normal_header";

interface KenmorePartialAlertProps {
  text: FreeTextType;
  header: { text: string };
  banner: {
    text: FreeTextType;
    color: string;
  };
}

const KenmorePartialAlert = (alert: KenmorePartialAlertProps) => {
  const { text, header, banner } = alert;

  return (
    <div className="kenmore-partial-alert__container">
      <NormalHeader text={header.text} accentPattern="dup-accent-pattern.svg" />
      <div className="kenmore-partial-alert__body">
        <div className="kenmore-partial-alert__body-text full-screen-alert__body-text">
          <FreeText lines={[text]} />
        </div>
      </div>

      <div className={classWithModifier("partial-alert", banner.color)}>
        <FreeText lines={[banner.text]} />
      </div>
    </div>
  );
};

export default KenmorePartialAlert;
