import React from "react";

import FreeText, { srcForIcon } from "Components/v2/free_text";

const DepartureAlert = ({ icon, text }) => {
  const imgSrc = srcForIcon(icon);

  return (
    <div className="departure-alert">
      <div className="departure-alert__icon">
        <img className="departure-alert__icon-image" src={imgSrc} />
      </div>
      <div className="departure-alert__text">
        <FreeText lines={{ text: text }} />
      </div>
    </div>
  );
};

const DepartureAlerts = ({ alerts }) => {
  return (
    <div className="departure-alerts">
      {alerts.map(({ id, ...data }) => (
        // @ts-expect-error
        <DepartureAlert {...data} key={id} />
      ))}
    </div>
  );
};

export default DepartureAlerts;
