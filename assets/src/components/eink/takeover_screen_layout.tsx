import React from "react";

const TakeoverScreenLayout = ({ apiResponse, size }): JSX.Element => {
  const psaName = apiResponse.psa_name;
  const imageSrc = `https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/${psaName}.png`;
  return (
    <div className={`${size}-screen-container`}>
      <img src={imageSrc} />
    </div>
  );
};

export default TakeoverScreenLayout;
