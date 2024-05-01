import React, { ComponentType } from "react";
import noDataPNG from "../../../../static/images/no-data-triptych.png";

interface Props {
  show_alternatives: boolean;
}

const NoData: ComponentType<Props> = () => {
  return (
    <>
      <div className="no-data-left">
        <img src={noDataPNG} />
      </div>
      <div className="no-data-middle">
        <img src={noDataPNG} />
      </div>
      <div className="no-data-right">
        <img src={noDataPNG} />
      </div>
    </>
  );
};

export default NoData;
