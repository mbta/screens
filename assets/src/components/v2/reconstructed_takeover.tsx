import React, { useEffect, useRef, useState } from "react";

import { classWithModifiers, imagePath } from "Util/util";
import DisruptionDiagram, {
  DisruptionDiagramData,
} from "./disruption_diagram/disruption_diagram";

interface ReconAlertProps {
  issue: string | any; // shouldn't be "any"
  location: string;
  cause: string;
  remedy: string;
  routes: any[]; // shouldn't be "any"
  effect: string;
  updated_at: string;
  disruption_diagram?: DisruptionDiagramData;
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

  const [diagramHeight, setDiagramHeight] = useState(0);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!ref.current) return;
    const resizeObserver = new ResizeObserver(() => {
      if (ref?.current) {
        setDiagramHeight(ref.current.clientHeight);
      }
    });
    resizeObserver.observe(ref.current);
    return () => resizeObserver.disconnect(); // clean up
  });

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
              <div className="alert-card__body__location ">{location}</div>
              {disruption_diagram && (
                <div
                  id="disruption-diagram-container"
                  className="disruption-diagram-container"
                  ref={ref}
                >
                  <DisruptionDiagram
                    {...disruption_diagram}
                    svgHeight={diagramHeight}
                  />
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
