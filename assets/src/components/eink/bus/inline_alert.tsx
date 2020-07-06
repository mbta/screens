import React from "react";

const InlineAlert = ({ alert }): JSX.Element => {
  return (
    <div className="inline-alert">
      <div className="inline-alert__badge">
        <img className="inline-alert__icon" src="/images/alert.svg" />
        <div className="inline-alert__text">Delays</div>
      </div>
    </div>
  );
};

export default InlineAlert;
