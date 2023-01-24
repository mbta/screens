import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_two: WidgetData;
}

const NormalBodyTwo: React.ComponentType<Props> = ({
  main_content_two: mainContent,
}) => {
  return (
    <div className="body-normal">
      <div className="widget-slot body-normal__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalBodyTwo;
