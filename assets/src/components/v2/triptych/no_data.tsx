import React, { ComponentType } from "react";
import LcdNoData from "Components/v2/lcd/no_data";

interface Props {
  show_alternatives: boolean;
}

const NoData: ComponentType<Props> = ({
  show_alternatives: showAlternatives,
}) => {
  // TODO: We likely want to show something different from the usual when we fail to fetch data for this screen type.
  return (
    <>
      <div className="no-data-left">
        <LcdNoData show_alternatives={showAlternatives} />
      </div>
      <div className="no-data-middle">
        <LcdNoData show_alternatives={showAlternatives} />
      </div>
      <div className="no-data-right">
        <LcdNoData show_alternatives={showAlternatives} />
      </div>
    </>
  );
};

export default NoData;
