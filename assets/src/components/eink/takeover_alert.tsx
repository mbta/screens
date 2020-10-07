import React from "react";

const TakeoverAlert = ({ filename }): JSX.Element => {
  const imageSrc = `https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/${filename}`;
  return (
    <div className="takeover-alert">
      <img src={imageSrc} />
    </div>
  );
};

export default TakeoverAlert;
