import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_right: WidgetData;
  secondary_content: WidgetData;
}

const NormalBodyRight: React.ComponentType<Props> = ({
  main_content_right: mainContentRight,
  secondary_content: secondaryContent,
}) => {
  return (
    <div className="body-normal-right">
      <div className="body-normal-right__main-content">
        <Widget data={mainContentRight} />
      </div>
      <div className="body-normal-right__secondary-content">
        <Widget data={secondaryContent} />
      </div>
    </div>
  );
};

export default NormalBodyRight;
