import React, { ComponentType } from "react";
import Loading from "Components/v2/bundled_svg/loading";

const coolBlack = "#171F26";

const LoadingLayout: ComponentType = () => {
  return (
    <div className="page-load-no-data-container">
      <div className="no-data__main-content">
        <div className="page-load-no-data__main-content__loading-icon-container">
          <Loading
            className="page-load-no-data__main-content__loading-icon"
            colorHex={coolBlack}
          />
        </div>
        <div className="page-load-no-data__main-content__heading">
          Loading...
        </div>
        <div className="page-load-no-data__main-content__subheading">
          This should only take a moment.
        </div>
      </div>
    </div>
  );
};

export default LoadingLayout;
