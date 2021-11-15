import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  left_sidebar: WidgetData;
  main_content: WidgetData;
  full_body_bottom_screen: WidgetData;
}

const BottomTakeoverBody: React.ComponentType<Props> = ({
  left_sidebar: leftSidebar,
  main_content: mainContent,
  full_body_bottom_screen: fullBodyBottomScreen,
}) => {
  return (
    <div className="body-bottom-takeover">
      <div className="body-bottom-takeover__left-sidebar">
        <Widget data={leftSidebar} />
      </div>
      <div className="body-bottom-takeover__main-content">
        <Widget data={mainContent} />
      </div>
      <div className="body-bottom-takeover__bottom-screen">
        <Widget data={fullBodyBottomScreen} />
      </div>
    </div>
  );
};

export default BottomTakeoverBody;
