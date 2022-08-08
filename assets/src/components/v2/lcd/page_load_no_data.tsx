import NoConnection from "Components/v2/bundled_svg/no_connection";
import React, { ComponentType } from "react";

const coolBlack = "#171F26";

const PageLoadNoData: ComponentType = () => {
  return (
    <div className="page-load-no-data-container">
      <div className="no-data__main-content">
        <div className="page-load-no-data__main-content__no-connection-icon-container">
          <NoConnection
            className="page-load-no-data__main-content__no-connection-icon"
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
