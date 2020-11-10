import React from "react";

const TakeoverAlert = ({ psaUrl }): JSX.Element => {
  return (
    <div className="takeover-alert">
      <img src={psaUrl} />
    </div>
  );
};

export default TakeoverAlert;
