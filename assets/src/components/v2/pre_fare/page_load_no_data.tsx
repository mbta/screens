import React, { ComponentType } from "react";
import LcdPageLoadNoData from "Components/v2/lcd/page_load_no_data";

const PageLoadNoData: ComponentType = () => {
  return (
    <>
      <div className="no-data-left">
        <LcdPageLoadNoData />
      </div>
      <div className="no-data-right">
        <LcdPageLoadNoData />
      </div>
    </>
  );
};

export default PageLoadNoData;
