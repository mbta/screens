import { classWithModifier } from "Util/utils";
import FreeText, { FreeTextType } from "Components/v2/free_text";

interface PartialAlertProps {
  text: FreeTextType;
  color: string;
}

const PartialAlert = (alert: PartialAlertProps) => {
  const { text, color } = alert;

  return (
    <div className={classWithModifier("partial-alert", color)}>
      <FreeText lines={text} />
    </div>
  );
};

export default PartialAlert;
