import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import { CSSTransition, TransitionGroup } from "react-transition-group";
import FlexZonePageIndicator from "Components/v2/flex/page_indicator";

interface Props {
  main_content: WidgetData;
  flex_zone: WidgetData;
  footer: WidgetData;
}

const NormalBody: React.ComponentType<Props> = ({
  main_content: mainContent,
  flex_zone: flexZone,
  footer,
}) => {
  const { page_index: pageIndex, num_pages: numPages } = flexZone;
  return (
    <div className="body-normal">
      <div className="body-normal__main-content">
        <Widget data={mainContent} />
      </div>
      <div className="body-normal__flex-zone">
        <TransitionGroup>
          <CSSTransition
            key={pageIndex}
            classNames="slide"
            unmountOnExit
            timeout={500}
          >
            <Widget data={flexZone} />
          </CSSTransition>
        </TransitionGroup>
        <FlexZonePageIndicator pageIndex={pageIndex} numPages={numPages} />
      </div>
      <div className="body-normal__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default NormalBody;
