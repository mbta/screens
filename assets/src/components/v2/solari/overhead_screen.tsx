import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_overhead: WidgetData;
  main_content_overhead: WidgetData;
}

const OverheadScreen: React.ComponentType<Props> = ({
  header_overhead: header,
  main_content_overhead: mainContent,
}) => {
  return (
    <div className="screen-overhead">
      <div className="screen-overhead__header">
        <Widget data={header} />
      </div>
      <div className="screen-overhead__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default OverheadScreen;
