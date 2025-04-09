import React, { ComponentType } from "react";
import NoConnection from "Images/svgr_bundled/live-data-none.svg";

const NoData: ComponentType = () => {
  return (
    <div className="no-data">
      <div className="no-data__header">
        <NoConnection width="90" height="90" color="#171F26" />
      </div>
      <div className="no-data__content">
        Live connection updates <br /> are temporarily unavailable.
      </div>
    </div>
  );
};

export default NoData;
