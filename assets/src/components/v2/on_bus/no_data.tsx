import React, { ComponentType } from "react";
import { imagePath } from "Util/utils";

const NoData: ComponentType = () => {
  return (
    <div className="screen-container">
      <div className="no-data__container">
        <div className="no-data__header">
          <div className="no-data__logo-container">
            <img
              className="no-data__logo-image"
              src={imagePath(`no-wifi.svg`)}
            />
          </div>
        </div>
        <div className="no-data__main-content">
          <div className="no-data__main-content__text">
            Live departure info is temporarily unavailable
          </div>
        </div>
        <div className="no-data__subcontent">
          <div className="no-data__subcontent__text">
            more on mbta.com/schedules.
          </div>
        </div>
      </div>
    </div>
  );
};

export default NoData;
