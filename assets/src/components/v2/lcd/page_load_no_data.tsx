import React, { ComponentType } from "react";
import Loading from "Images/loading.svg";

const coolBlack = "#171F26";

const PageLoadNoData: ComponentType = () => {
  return (
    <div className="page-load-no-data-container">
      <div className="no-data__main-content">
        <div className="page-load-no-data__main-content__loading-icon-container">
          <Loading
            width="128"
            height="128"
            className="page-load-no-data__main-content__loading-icon"
            color={coolBlack}
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

export default PageLoadNoData;
