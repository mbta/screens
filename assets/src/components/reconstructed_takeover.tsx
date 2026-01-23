import type { ComponentType } from "react";
import { classWithModifiers, imagePath } from "Util/utils";
import DisruptionDiagram, {
  DisruptionDiagramData,
} from "./disruption_diagram/disruption_diagram";
import FreeText, { FreeTextType } from "./free_text";

interface ReconAlertProps {
  issue: string | any; // shouldn't be "any"
  location: string | FreeTextType;
  cause: string;
  remedy: string;
  show_alternate_route_text: boolean;
  routes: any[]; // shouldn't be "any"
  effect: string;
  updated_at: string;
  end_time?: string;
  disruption_diagram?: DisruptionDiagramData;
  urgent: boolean;
}

const ReconstructedTakeover: ComponentType<ReconAlertProps> = (alert) => {
  const {
    cause,
    effect,
    issue,
    location,
    remedy,
    show_alternate_route_text,
    routes,
    updated_at,
    end_time,
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
              <h1 className="alert-card__body__issue">{issue}</h1>
              <div className="alert-card__body__location body-2">
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
          <div className="alert-card__footer body-4">
            <div className="alert-card__footer__cause">
              {cause && `Cause: ${cause}`}
            </div>
            <div className="alert-card__footer__updated-at">
              {end_time ? (
                <span className="bold">Through {end_time}</span>
              ) : (
                <span>Updated {updated_at}</span>
              )}
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
                <h1 className="alert-card__body__shuttle-remedy">{remedy}</h1>
                <div className="alert-card__body__accessibility-info">
                  <div className="alert-card__body__accessibility-info--text body-2">
                    All shuttle buses are accessible
                  </div>
                  <img
                    className="alert-card__body__isa-icon"
                    src={imagePath("ISA_Blue.svg")}
                  />
                </div>
              </>
            ) : (
              <h3 className="alert-card__body__remedy">
                {show_alternate_route_text ? (
                  <>
                    <span className="alert-card__body__remedy--alternate-route">
                      Find alternate route at{" "}
                    </span>
                    mbta.com/alerts
                  </>
                ) : (
                  remedy
                )}
              </h3>
            )}
          </div>
          <div className="alert-card__footer body-4">
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
