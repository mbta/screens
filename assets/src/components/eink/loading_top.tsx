import React from "react";
import { imagePath } from "Util/util";
import Loading from "Components/v2/bundled_svg/loading";

const LoadingTop = (): JSX.Element => {
  return (
    <div className="page-load-no-data-container-top">
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
        <div className="page-load-no-data__main-content__loading-icon-container">
          <Loading
            className="page-load-no-data__main-content__loading-icon"
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
  );
};

export default LoadingTop;
