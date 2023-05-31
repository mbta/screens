import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  paged_main_content_left: WidgetData;
}

const BodyLeftFlex: React.ComponentType<Props> = ({
  paged_main_content_left: pagedMainContentLeft,
}) => {
  return (
    <div className="body-left-flex">
      <div className="body-left-flex__paged-main-content">
        <Widget data={pagedMainContentLeft} />
      </div>
    </div>
  );
};

export default BodyLeftFlex;
