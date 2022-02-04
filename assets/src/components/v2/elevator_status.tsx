import React, { ComponentType, useEffect, useState } from "react";
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
    pageToRender = <DetailPageComponent detailPage={page as DetailPage} />;
  } else if (instanceOfListPage(page)) {
    pageToRender = <ListPageComponent listPage={page as ListPage} />;
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

interface DetailPageProps {
  detailPage: DetailPage;
}

const DetailPageComponent: ComponentType<DetailPageProps> = ({
  detailPage,
}) => {
  const {
    station: {
      is_at_home_stop: isAtHomeStop,
      name,
      icons,
      elevator_closures: elevatorClosures,
    },
  } = detailPage;
  const {
    header_text: headerText,
    description,
    timeframe,
  } = elevatorClosures[0];
  return (
    <div className="detail-page">
      <div className="detail-page__closure">
        <div className="detail-page__closure-location">
          <div className="detail-page__closure-icon">
            <img src="/images/elevator-status-outage-black.svg" />
          </div>
          <div className="detail-page__closure-location-text">
            {isAtHomeStop ? "At this station" : name}
          </div>
          <img src="/images/elevator-status-you-are-here.svg" />
        </div>
        <div className="detail-page__closure-header">{headerText}</div>
        <div className="detail-page__timeframe">
          <img src="/images/elevator-status-alert-black.svg" />
          <div className="detail-page__timeframe-text-start">
            {timeframe.happening_now ? "NOW" : "Upcoming"}
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
