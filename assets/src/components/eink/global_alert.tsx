import moment from "moment";
import "moment-timezone";
import React from "react";

const iconForAlert = alert => {
  // For now, shuttles will show a bus icon, and everything else will
  // just show the default alert icon.
  return { shuttle: "bus-negative-white" }[alert.effect] || "alert";
};

const GlobalAlert = ({ alert }): JSX.Element => {
  const updatedTime = moment(alert.updated_at);
  return (
    <div className="global-alert">
      <div className="global-alert__header">
        <div className="global-alert__icon-container">
          <img
            className="global-alert__icon-image"
            src={`/images/${iconForAlert(alert)}.svg`}
          />
        </div>
        <div className="global-alert__header-effect">
          {alert.effect.replace("_", " ").replace(/\w\S*/g, txt => {
            return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
          })}
        </div>
        <div className="global-alert__header-timestamp">
          Updated <br />
          {updatedTime.tz("America/New_York").format("M/D/Y · h:mm A")}
        </div>
      </div>

      <div className="global-alert__body">
        <div className="global-alert__body-description">{alert.header}</div>
      </div>
    </div>
  );
};

export default GlobalAlert;
