import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content: WidgetData;
}

const NormalScreen: React.ComponentType<Props> = ({
  main_content: mainContent,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__body">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalScreen;
