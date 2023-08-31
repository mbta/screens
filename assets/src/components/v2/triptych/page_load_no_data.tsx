import React, { ComponentType } from "react";
import { imagePath } from "Util/util";

const PageLoadNoData: ComponentType = () => {
  return (
    <>
      <div className="no-data-left">
        <img src={imagePath("loading-triptych.png")} />
      </div>
      <div className="no-data-middle">
        <img src={imagePath("loading-triptych.png")} />
      </div>
      <div className="no-data-right">
        <img src={imagePath("loading-triptych.png")} />
      </div>
    </>
  );
};

export default PageLoadNoData;
