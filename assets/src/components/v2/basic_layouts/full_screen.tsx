import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_screen: WidgetData;
}

const FullScreen: React.ComponentType<Props> = ({
  full_screen: fullScreen,
}) => {
  return (
    <div className="full-screen">
      <Widget data={fullScreen} />
    </div>
  );
};

export default FullScreen;
