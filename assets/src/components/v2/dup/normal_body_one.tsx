import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header: WidgetData;
  main_content_primary: WidgetData;
}

const NormalBodyOne: React.ComponentType<Props> = ({
  header,
  main_content_primary: mainContentPrimary,
}) => {
  return (
    <div className="body-normal">
      <div className="body-normal__header">
        <Widget data={header} />
      </div>
      <div className="body-normal__main-content">
        <Widget data={mainContentPrimary} />
      </div>
    </div>
  );
};

export default NormalBodyOne;
