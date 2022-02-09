import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_left: WidgetData;
}

const NormalBodyLeft: React.ComponentType<Props> = ({
  main_content_left: mainContentLeft,
}) => {
  return (
    <div className="body-normal-left">
      <div className="body-normal-left__main-content">
        <Widget data={mainContentLeft} />
      </div>
    </div>
  );
};

export default NormalBodyLeft;
