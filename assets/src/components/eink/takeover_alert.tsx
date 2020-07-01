import React from "react";

const TakeoverAlert = ({ name, mode }): JSX.Element => {
  const imageSrc = `https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/${name}.png`;
  return (
    <div className="takeover-alert">
      <img src={imageSrc} />
    </div>
  );
};

export default TakeoverAlert;
