import React from "react";

const TakeoverAlert = ({ name }): JSX.Element => {
  const imageSrc = `https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/${name}`;
  return (
    <div className="takeover-alert">
      <img src={imageSrc} />
    </div>
  );
};

export default TakeoverAlert;
