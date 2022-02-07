import React, { ComponentType, useEffect, useState } from "react";
import { classWithModifier } from "Util/util";
import FlexZonePageIndicator from "./flex/page_indicator";

type Page = ListPage | DetailPage;

interface DetailPage {
  station: Station;
}

interface ListPage {
  stations: Station[];
}

interface Station {
  name: string;
  icons: Icon[];
  elevator_closures: Closure[];
  is_at_home_stop: boolean;
}

interface Closure {
  elevator_name: string;
  elevator_id: string;
  header_text: string;
  timeframe: {
    happening_now: boolean;
    active_period: ActivePeriod[];
  };
  description: string;
}

interface ActivePeriod {
  start: string;
  end: string;
}

type Icon =
  | "orange"
  | "red"
  | "green"
  | "blue"
  | "silver"
  | "rail"
  | "bus"
  | "mattapan";

interface Props {
  pages: Page[];
  lastUpdate: number;
  onFinish: Function;
}

const ElevatorStatus: ComponentType<Props> = ({
  pages,
  lastUpdate,
  onFinish,
}) => {
  const [isFirstRender, setIsFirstRender] = useState(true);
  const [pageIndex, setPageIndex] = useState(0);

  useEffect(() => {
    if (isFirstRender) {
      setIsFirstRender(false);
    } else {
      setPageIndex((i) => i + 1);
    }
  }, [lastUpdate]);

  useEffect(() => {
    if (pageIndex === pages.length - 1) {
      onFinish();
    }
  }, [pageIndex]);

  const page = pages[pageIndex];
  let pageToRender;
  if (page == null) return null;
  if (instanceOfDetailPage(page)) {
    pageToRender = <DetailPageComponent {...(page as DetailPage)} />;
  } else if (instanceOfListPage(page)) {
    pageToRender = <ListPageComponent {...(page as ListPage)} />;
  } else {
    return null;
  }

  return (
    <>
      <div className="elevator-status">
        <div className="elevator-status__header">
          <div className="elevator-status__header-text">Elevator Closures</div>
          <img src="/images/elevator-status-elevator.svg" />
        </div>
        {pageToRender}
        <div className="elevator-status__footer">
          <div className="elevator-status__footer-text">
            For more elevator alerts and directions to alternate accessible
            paths, visit mbta.com/alerts/access or call 800-392-8100
          </div>
        </div>
      </div>
      <FlexZonePageIndicator numPages={pages.length} pageIndex={pageIndex} />
    </>
  );
};

const instanceOfDetailPage = (page: Page): page is DetailPage => {
  return (page as DetailPage).station !== undefined;
};

const instanceOfListPage = (page: Page): page is ListPage => {
  return (page as ListPage).stations !== undefined;
};

const getLocationHeadingIcon = (isAtHomeStop: boolean, happeningNow: boolean) =>
  isAtHomeStop && happeningNow ? (
    <img
      className="detail-page__closure-heading-icon"
      src="/images/elevator-status-outage-red.svg"
    />
  ) : (
    <img
      className="detail-page__closure-heading-icon"
      src="/images/elevator-status-outage-black.svg"
    />
  );

const getRouteModeHereIcons = (isAtHomeStop: boolean, icons: Icon[]) =>
  isAtHomeStop ? (
    <img
      className="detail-page__closure-you-are-here-icon"
      src="/images/elevator-status-you-are-here.svg"
    />
  ) : (
    // <div className="detail-page__closure-route-mode-icons">ICONS GO HERE</div>
    icons.map((icon) => (
      <img
        className="detail-page__closure-route-mode-icons"
        src={"/images/elevator-status-" + icon + ".svg"}
      />
    ))
  );

const getTimeframeHeadingIcon = (
  isAtHomeStop: boolean,
  happeningNow: boolean
) =>
  isAtHomeStop && happeningNow ? (
    <img
      className="detail-page__closure-heading-icon"
      src="/images/elevator-status-alert-red.svg"
    />
  ) : isAtHomeStop ? (
    <img
      className="detail-page__closure-heading-icon"
      src="/images/elevator-status-alert-black.svg"
    />
  ) : (
    <img
      className="detail-page__closure-heading-icon"
      src="/images/elevator-status-alert-gray.svg"
    />
  );

const DetailPageComponent: ComponentType<DetailPage> = ({ station }) => {
  const {
    is_at_home_stop: isAtHomeStop,
    name,
    icons,
    elevator_closures: elevatorClosures,
  } = station;
  const {
    header_text: headerText,
    description,
    timeframe,
  } = elevatorClosures[0];

  const { happening_now: happeningNow } = timeframe;

  return (
    <div className="detail-page">
      <div
        className={classWithModifier(
          "detail-page__closure",
          isAtHomeStop && happeningNow ? "active-at-home" : ""
        )}
      >
        <div className="detail-page__closure-location">
          <div className="detail-page__closure-heading-icon-container">
            {getLocationHeadingIcon(isAtHomeStop, happeningNow)}
          </div>
          <div className="detail-page__closure-location-text">
            {isAtHomeStop ? "At this station" : name}
          </div>
          <div className="detail-page__closure-route-mode-here-icon-container">
            {getRouteModeHereIcons(isAtHomeStop, icons)}
          </div>
        </div>
        <div className="detail-page__closure-header">{headerText}</div>
        <div
          className={
            "detail-page__timeframe" +
            (isAtHomeStop && happeningNow ? " text-red" : "")
          }
        >
          <div className="detail-page__closure-heading-icon-container">
            {getTimeframeHeadingIcon(isAtHomeStop, happeningNow)}
          </div>
          <div className="detail-page__timeframe-text-start">
            {happeningNow ? "NOW" : "Upcoming"}
          </div>
          <div className="detail-page__timeframe-text-end">
            Until further notice
          </div>
        </div>
        <div className="detail-page__description">{description}</div>
      </div>
    </div>
  );
};

interface ListPageProps {
  listPage: ListPage;
}

const ListPageComponent: ComponentType<ListPageProps> = ({ listPage }) => {
  return null;
};

export default ElevatorStatus;
