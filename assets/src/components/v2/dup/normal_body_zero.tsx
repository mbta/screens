import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_zero: WidgetData;
}

const NormalBodyZero: React.ComponentType<Props> = ({
  main_content_zero: mainContent,
}) => {
  return (
    <div className="body-normal">
      <div className="widget-slot body-normal__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalBodyZero;
