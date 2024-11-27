import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content: WidgetData;
}

const NormalScreen = ({ main_content: mainContent }: Props) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__body">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalScreen;
