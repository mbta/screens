import React, { ComponentType } from "react";
import LoadingHourglass from "Components/v2/bundled_svg/loading_hourglass";

const coolBlack = "#171F26";

const PageLoadNoData: ComponentType = () => {
  return (
    <div className="page-load-no-data-container">
      <div className="no-data__main-content">
        <div className="page-load-no-data__main-content__loading-hourglass-container">
          <LoadingHourglass
            className="page-load-no-data__main-content__loading-hourglass-icon"
            colorHex={coolBlack}
          />
        </div>
        <div className="page-load-no-data__main-content__text">
          <p>Loading...</p>
          <p>This should only take a moment</p>
        </div>
      </div>
    </div>
  );
};

export default PageLoadNoData;
