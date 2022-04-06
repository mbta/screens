import React, { ComponentType } from "react";
import { classWithModifier, classWithModifiers, imagePath } from "Util/util";

import RoutePill, {routePillKey} from "Components/v2/departures/route_pill";
import { ReconAlertProps } from "./reconstructed_takeover";
import useTextResizer from "Hooks/v2/use_text_resizer";

interface AlertCardProps {
  urgent: boolean;
  children: React.ReactNode;
}

const isPIOAlert = (effect: string, urgent: boolean, routes: any[]) => {
  return (effect==="delay" && !urgent) || (effect!=="station_closure" && routes.length > 1)
}

const ReconstructedAlert: ComponentType<ReconAlertProps> = (alert) => {

  const { cause, effect, issue, location, remedy, routes, urgent } = alert

  const BODY_SIZES = isPIOAlert(effect, urgent, routes) ?
    ["extra-small", "small", "large"]
    : ["small", "large", "extra-large"];
  const { ref: descriptionRef, size: descriptionSize } = useTextResizer({
    sizes: BODY_SIZES,
    maxHeight: 360,
    resetDependencies: [issue, cause],
  });

  const modifiers = [
    "large-flex",
    routes.length > 1 ? "yellow" : routes[0].color,
  ]

  if (urgent) modifiers.push("urgent")

  return (
    <div className={classWithModifiers("alert-container", modifiers)}>
      <FlexZoneAlertCard urgent={urgent}>
        <>
          <div className="alert-card__body">
            <div className={"alert-card__body__route-pills"}>
              {routes.map((pill) => (
                <RoutePill {...pill} key={routePillKey(pill)} />
              ))}
            </div>
            {effect === "delay" && <div className={"alert-card__body__delay-notice"}>
              Delay
            </div>}
            <div className="alert-card__body__icon">
              <img
                className="alert-card__body__icon-image"
                src={imagePath(filenameForFlexZoneIcon(effect, urgent))}
              />
            </div>
            <div className={classWithModifier(
                "alert-card__body__content",
                descriptionSize
              )}
              ref={descriptionRef}
            >
              <div className="alert-card__body__issue">
                { isPIOAlert(effect, urgent, routes) ?
                  <span className="medium-bold">{issue}</span>
                  : <><span className="bold">{ issue } {location}</span> { cause }</>
                }
              </div>
              <div className="alert-card__body__remedy">
                {remedy}
                {effect === "shuttle" &&
                  <img
                    className="alert-card__body__isa-icon"
                    src={imagePath("ISA_Blue.svg")}
                  />
                }
              </div>
            </div>
          </div>
          <div className="alert-card__footer">
            <div className="alert-card__footer__alerts-url">mbta.com/alerts</div>  
          </div>
        </>
      </FlexZoneAlertCard>
    </div>
  );
};

const FlexZoneAlertCard: ComponentType<AlertCardProps> = ({ urgent, children }) => (
  <svg
    className="alert-card"
    width="1064px" height="616px" viewBox="0 0 1064 616"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
  >
    <defs>
      <path d="M210.627417,19.372583 L29.372583,200.627417 C23.3714189,206.628581 20,214.767906 20,223.254834 L20,554 C20,571.673112 34.326888,586 52,586 L1012,586 C1029.67311,586 1044,571.673112 1044,554 L1044,42 C1044,24.326888 1029.67311,10 1012,10 L233.254834,10 C224.767906,10 216.628581,13.3714189 210.627417,19.372583 Z" id="path-1"></path>
      <filter x="-3.4%" y="-4.3%" width="106.8%" height="112.2%" filterUnits="objectBoundingBox" id="filter-2">
        <feOffset dx="0" dy="10" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
        <feGaussianBlur stdDeviation="10" in="shadowOffsetOuter1" result="shadowBlurOuter1"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 0.09   0 0 0 0 0.122   0 0 0 0 0.15  0 0 0 0.25 0" type="matrix" in="shadowBlurOuter1"></feColorMatrix>
      </filter>
    </defs>
    <g id="Primary-Screen-Master-Symbols" stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="Background-Shape-Copy" transform="translate(532.000000, 298.000000) scale(-1, 1) translate(-532.000000, -298.000000) ">
        <use fill="black" fillOpacity="1" filter="url(#filter-2)" xlinkHref="#path-1"></use>
        <use fill={urgent ? "#171F26" : "#e6e4e1"} fillRule="evenodd" xlinkHref="#path-1"></use>
      </g>
    </g>
    <foreignObject x="20" y="10" width="1024" height="580">
      {children}
    </foreignObject>
  </svg>
);

const filenameForFlexZoneIcon = (effect: string, urgent: boolean) => {
  switch (effect) {
    case "shuttle":
      return urgent ? "alert-widget-icon-bus--color-urgent.svg" : "alert-widget-icon-bus--color.svg";
    case "delay":
      return urgent ? "clock-with-border-urgent.svg" :"clock-with-border.svg";
    default:
      return urgent ? "alert-widget-icon-x--color-urgent.svg" : "alert-widget-icon-x--color.svg";
  }
}

export default ReconstructedAlert;
