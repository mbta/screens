import type { ComponentType } from "react";
import RoutePill, { Pill } from "./route_pill";
import NoServiceIcon from "Images/no-service.svg";
import ShuttleBusIcon from "Images/shuttle-icon.svg";
import { getHexColor } from "Util/svg_utils";
import FreeText, { FreeTextType } from "Components/free_text";

type AlertIcon =
  ({ effect: "suspension" } & { color: string }) | { effect: "shuttle" };

type AlertRow = {
  id: string;
  route: Pill;
  header_text: FreeTextType;
  additional_text: FreeTextType;
  icon: AlertIcon;
};

const AlertRow: ComponentType<AlertRow> = ({
  route,
  header_text,
  additional_text,
  icon,
}) => {
  return (
    <div className="departures-alert">
      <div className="departures-alert__pill-and-text-container">
        <div className="departure-row__route departures-alert__route">
          <RoutePill pill={route} />
        </div>
        <div className="departures-alert__text-container">
          <FreeText
            className="departures-alert__disruption-text"
            lines={header_text}
          />
          <FreeText
            className="departures-alert__additional-text"
            lines={additional_text}
          />
        </div>
      </div>
      {effectIcon(icon)}
    </div>
  );
};

const effectIcon = (icon: AlertIcon) => {
  if (icon.effect === "suspension") {
    return (
      <NoServiceIcon
        className="departures-alert__icon"
        color={getHexColor(icon.color)}
      />
    );
  } else if (icon.effect === "shuttle") {
    return <ShuttleBusIcon className="departures-alert__icon" />;
  }
};

export default AlertRow;
