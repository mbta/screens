import React from "react";

const Psa = ({ psaName, currentTimeString }): JSX.Element => {
  const imageSrc = `https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/${psaName}.png`;
  return (
    <div className="psa" key={currentTimeString}>
      <img src={imageSrc} />
      <div className="psa__progress-bar" />
    </div>
  );
};

export default Psa;
