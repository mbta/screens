import React, { ComponentType } from "react";
import { imagePath } from "Util/util";
import NoConnection from "Components/v2/bundled_svg/no_connection";
import BottomScreenFiller from "Components/v2/eink/bottom_screen_filler";

const NoData: ComponentType = () => {
  return (
    <div className="no-data-container">
      <div className="no-data__top-screen">
        <div className="no-data__header">
          <div className="no-data__logo-container">
            <img
              className="no-data__logo-image"
              src={imagePath(`logo-white.svg`)}
            />
          </div>
          <div className="no-data__header-text-container">
            <div className="no-data__header-text">
              Thank you for your patience
            </div>
          </div>
        </div>
        <div className="no-data__main-content">
          <div className="no-data__main-content__no-connection-icon-container">
            <NoConnection
              className="no-data__main-content__no-connection-icon"
              colorHex="#000000"
            />
          </div>
          <div className="no-data__main-content__heading">
            Live updates are temporarily unavailable.
          </div>
          <div className="no-data__hairline" />
          <div className="no-data__main-content__subheading">
            Our apologies for the inconvenience.
          </div>
        </div>
      </div>
      <BottomScreenFiller />
    </div>
  );
};

export default NoData;
