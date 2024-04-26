import React from "react";

import { classWithModifiers, imagePath } from "Util/util";
import DisruptionDiagram, {
  DisruptionDiagramData,
} from "./disruption_diagram/disruption_diagram";
import FreeText, { FreeTextType } from "./free_text";

interface ReconAlertProps {
  issue: string | any; // shouldn't be "any"
  location: string | FreeTextType;
  cause: string;
  remedy: string;
  routes: any[]; // shouldn't be "any"
  effect: string;
  updated_at: string;
  disruption_diagram?: DisruptionDiagramData;
  urgent: boolean;
}

const ReconstructedTakeover: React.ComponentType<ReconAlertProps> = (alert) => {
  const {
    cause,
    effect,
    issue,
    location,
    remedy,
    routes,
    updated_at,
    disruption_diagram,
  } = alert;

  return (
    <>
      <div
        className={classWithModifiers("alert-container", [
          "takeover",
          routes.length > 1 ? "yellow" : routes[0].color,
        ])}
      >
        <div className="alert-card alert-card--left">
          <div className="alert-card__body">
            <div className="container">
              <img
                className="alert-card__body__icon"
                src={imagePath("no-service-black.svg")}
              />
              <div className="alert-card__body__issue">{issue}</div>
              <div className="alert-card__body__location ">
                {typeof location === "string" ? (
                  location
                ) : (
                  <FreeText lines={location} />
                )}
              </div>
              {disruption_diagram && (
                <div
                  id="disruption-diagram-container"
                  className="disruption-diagram-container"
                >
                  <DisruptionDiagram {...disruption_diagram} />
                </div>
              )}
            </div>
          </div>
          <div className="alert-card__footer">
            <div className="alert-card__footer__cause">
              {cause && `Cause: ${cause}`}
            </div>
            <div className="alert-card__footer__updated-at">
              Updated <span className="bold">{updated_at}</span>
            </div>
          </div>
        </div>
      </div>
      <div
        className={classWithModifiers("alert-container", [
          "takeover",
          "right",
          routes.length > 1 ? "yellow" : routes[0].color,
        ])}
      >
        <div className="alert-card">
          <div className="alert-card__body">
            {effect === "shuttle" ? (
              <>
                <img
                  className="alert-card__body__shuttle-icon"
                  src={imagePath("bus-black.svg")}
                />
                <div className="alert-card__body__shuttle-remedy">{remedy}</div>
                <div className="alert-card__body__accessibility-info">
                  <img
                    className="alert-card__body__isa-icon"
                    src={imagePath("ISA_Blue.svg")}
                  />
                  <div className="alert-card__body__accessibility-info--text">
                    All shuttle buses are accessible
                  </div>
                </div>
              </>
            ) : (
              <div className="alert-card__body__remedy">{remedy}</div>
            )}
          </div>
          <div className="alert-card__footer">
            <div className="alert-card__footer__alerts-url">
              mbta.com/alerts
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ReconstructedTakeover;
export { ReconAlertProps };
