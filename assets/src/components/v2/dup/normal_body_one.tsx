import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_one: WidgetData;
}

const NormalBodyOne: React.ComponentType<Props> = ({
  main_content_one: mainContent,
}) => {
  return (
    <div className="body-normal">
      <div className="widget-slot body-normal__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalBodyOne;
