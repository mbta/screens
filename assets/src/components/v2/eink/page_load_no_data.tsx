import React, { ComponentType } from "react";
import { imagePath } from "Util/util";
import BottomScreenFiller from "Components/v2/eink/bottom_screen_filler";
import LoadingHourglass from "Components/v2/bundled_svg/loading_hourglass";

const PageLoadNoData: ComponentType = () => {
  return (
    <div className="page-load-no-data-container">
      <div className="page-load-no-data__top-screen">
        <div className="page-load-no-data__header">
          <div className="page-load-no-data__logo-container">
            <img
              className="page-load-no-data__logo-image"
              src={imagePath(`logo-white.svg`)}
            />
          </div>
          <div className="page-load-no-data__header-text-container">
            <div className="page-load-no-data__header-text">
              Thank you for your patience
            </div>
          </div>
        </div>
        <div className="page-load-no-data__main-content">
          <div className="page-load-no-data__main-content__loading-hourglass-icon-container">
            <LoadingHourglass
              className="page-load-no-data__main-content__loading-hourglass-icon"
              colorHex="#000000"
            />
          </div>
          <div className="page-load-no-data__main-content__heading">
            Loading...
          </div>
          <div className="page-load-no-data__hairline" />
          <div className="page-load-no-data__main-content__subheading">
            This should only take a moment.
          </div>
        </div>
      </div>
      <BottomScreenFiller />
    </div>
  );
};

export default PageLoadNoData;
