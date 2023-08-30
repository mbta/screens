import React, { ComponentType } from "react";
import { imagePath } from "Util/util";

interface Props {
  show_alternatives: boolean;
}

const NoData: ComponentType<Props> = () => {
  return (
    <>
      <div className="no-data-left">
        <img src={imagePath("no-data-triptych.png")} />
      </div>
      <div className="no-data-middle">
        <img src={imagePath("no-data-triptych.png")} />
      </div>
      <div className="no-data-right">
        <img src={imagePath("no-data-triptych.png")} />
      </div>
    </>
  );
};

export default NoData;
