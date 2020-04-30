import React from "react";

const TakeoverAlert = ({ mode }): JSX.Element => {
  if (!["bus", "subway"].includes(mode)) {
    return null;
  }

  return (
    <div className="takeover-alert">
      <img src={`/images/covid-flexzone-${mode}.png`} />
    </div>
  );
};

export default TakeoverAlert;
