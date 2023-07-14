import React from "react";

import { classWithModifiers, imagePath } from "Util/util";
import DisruptionDiagram, {
  DiscreteDisruptionDiagram,
} from "./disruption_diagram/disruption_diagram";

interface ReconAlertProps {
  issue: string | any; // shouldn't be "any"
  location: string;
  cause: string;
  remedy: string;
  routes: any[]; // shouldn't be "any"
  effect: string;
  updated_at: string;
}

const ReconstructedTakeover: React.ComponentType<ReconAlertProps> = (alert) => {
  const { cause, effect, issue, location, remedy, routes, updated_at } = alert;

  const props: DiscreteDisruptionDiagram = {
    effect: "station_closure",
    line: "blue",
    current_station_slot_index: 4,
    closed_station_slot_indices: [4],
    slots: [
      { type: "terminal", label_id: "place-bomnl" },
      {
        label: { full: "Government Center", abbrev: "St. Paul St" },
        show_symbol: true,
      },
      {
        label: { full: "State", abbrev: "Kent St" },
        show_symbol: true,
      },
      {
        label: { full: "Aquarium", abbrev: "Hawes St" },
        show_symbol: true,
      },
      {
        label: { full: "Maverick", abbrev: "St. Mary's" },
        show_symbol: true,
      },
      {
        label: { full: "Airport", abbrev: "Kenmore" },
        show_symbol: true,
      },
      {
        label: { full: "Wood Island", abbrev: "Hynes" },
        show_symbol: true,
      },
      {
        label: { full: "Orient Heights", abbrev: "Copley" },
        show_symbol: true,
      },
      {
        label: { full: "Suffolk Downs", abbrev: "Arlington" },
        show_symbol: true,
      },
      {
        label: { full: "Beachmont", abbrev: "Boylston" },
        show_symbol: true,
      },
      {
        label: { full: "Revere Beach", abbrev: "Park St" },
        show_symbol: true,
      },
      { type: "terminal", label_id: "place-wondl" },
    ],
  };

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
            <img
              className="alert-card__body__icon"
              src={imagePath("no-service-black.svg")}
            />
            <div className="alert-card__body__issue">{issue}</div>
            <div className="alert-card__body__location ">{location}</div>
            <div style={{ height: 408, width: 904 }}>
              <DisruptionDiagram {...props} />
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
