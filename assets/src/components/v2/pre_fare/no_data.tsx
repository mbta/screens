import React, { ComponentType } from "react";
import { default as LcdNoData } from "Components/v2/lcd/no_data";

interface Props {
  show_alternatives: boolean;
}

const NoData: ComponentType<Props> = ({
  show_alternatives: showAlternatives,
}) => {
  return (
    <>
      <div className="no-data-left">
        <LcdNoData show_alternatives={showAlternatives} />{" "}
      </div>
      <div className="no-data-right">
        <LcdNoData show_alternatives={showAlternatives} />{" "}
      </div>
    </>
  );
};

export default NoData;
