import React from "react";

const Psa = ({ psaUrl, currentTimeString }): JSX.Element => {
  return (
    <div className="psa" key={currentTimeString}>
      <img src={psaUrl} />
      <div className="psa__progress-bar" />
    </div>
  );
};

export default Psa;
