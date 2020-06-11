import React from "react";

const Psa = ({ psaName, currentTimeString }): JSX.Element => {
  const imageSrc = `https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/${psaName}.png`;
  return (
    <div className="screen-container__flex-space" key={currentTimeString}>
      <img src={imageSrc} />
    </div>
  );
};

export default Psa;
