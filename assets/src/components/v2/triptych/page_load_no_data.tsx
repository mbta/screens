import React, { ComponentType } from "react";
import loadingPNG from "Images/loading-triptych.png";

const PageLoadNoData: ComponentType = () => {
  return (
    <>
      <div className="no-data-left">
        <img src={loadingPNG} />
      </div>
      <div className="no-data-middle">
        <img src={loadingPNG} />
      </div>
      <div className="no-data-right">
        <img src={loadingPNG} />
      </div>
    </>
  );
};

export default PageLoadNoData;
