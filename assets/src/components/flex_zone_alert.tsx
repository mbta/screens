import moment from "moment";
import "moment-timezone";
import React from "react";

const iconForAlert = alert => {
  return (
    {
      SERVICE_CHANGE: "alert",
      DETOUR: "bus",
      STOP_MOVE: "no-service",
      STOP_CLOSURE: "logo-white"
    }[alert.effect] || "alert"
  );
};

const FlexZoneAlert = ({ alert }): JSX.Element => {
  const updatedTime = moment(alert.updated_at);
  return (
    <div className="alert-container">
      <div className="alert-header">
        <div className="alert-header-icon-container">
          <img
            className="alert-icon-image"
            src={`images/${iconForAlert(alert)}.svg`}
          />
        </div>
        <div className="alert-header-effect">
          {alert.effect.replace("_", " ").replace(/\w\S*/g, txt => {
            return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
          })}
        </div>
        <div className="alert-header-timestamp">
          Updated <br />
          {updatedTime.tz("America/New_York").format("M/D/Y · h:mm A")}
        </div>
      </div>

      <div className="alert-body">
        <div className="alert-body-description">{alert.header}</div>
      </div>
    </div>
  );
};

export default FlexZoneAlert;
