import moment from "moment";
import React, { ComponentType } from "react";
import { classWithModifier, imagePath } from "Util/util";
import FlexZonePageIndicator from "./flex/page_indicator";
import makePersistentCarousel, {
  PageRendererProps,
} from "./persistent_carousel";

type ElevatorStatusPage = ListPage | DetailPage;

interface DetailPage {
  station: DetailPageStation;
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

interface DetailPageStation extends Station {
  elevator_closures: [Closure];
}

interface Closure {
  elevator_name: string;
  elevator_id: string;
  header_text: string;
  timeframe: {
    happening_now: boolean;
    active_period: ActivePeriod;
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

type Props = PageRendererProps<ElevatorStatusPage>;

const ElevatorStatus: ComponentType<Props> = ({
  page,
  pageIndex,
  numPages,
}) => {
  let pageToRender;
  if (instanceOfDetailPage(page)) {
    pageToRender = <DetailPageComponent {...page} />;
  } else if (instanceOfListPage(page)) {
    pageToRender = <ListPageComponent {...page} />;
  } else {
    throw new Error("Unknown or null ElevatorStatus page.");
  }

  return (
    <>
      <div className="elevator-status">
        <div className="elevator-status__header">
          <div className="elevator-status__header-text">Elevator Closures</div>
          <img src={imagePath("elevator-status-elevator.svg")} />
        </div>
        {pageToRender}
        <div className="elevator-status__footer">
          <div className="elevator-status__footer-text">
            For more elevator alerts and directions to alternate accessible
            paths, visit mbta.com/alerts/access or call 800-392-8100
          </div>
        </div>
      </div>
      <FlexZonePageIndicator numPages={numPages} pageIndex={pageIndex} />
    </>
  );
};

const instanceOfDetailPage = (page: ElevatorStatusPage): page is DetailPage => {
  return (page as DetailPage).station !== undefined;
};

const instanceOfListPage = (page: ElevatorStatusPage): page is ListPage => {
  return (page as ListPage).stations !== undefined;
};

const LocationHeadingIcon = ({
  isAtHomeStop,
  happeningNow,
}: {
  isAtHomeStop: boolean;
  happeningNow: boolean;
}): JSX.Element =>
  isAtHomeStop && happeningNow ? (
    <img
      className="detail-page__closure-outage-icon"
      src={imagePath("elevator-status-outage-red.svg")}
    />
  ) : (
    <img
      className="detail-page__closure-outage-icon"
      src={imagePath("elevator-status-outage-black.svg")}
    />
  );

const HereIcon: ComponentType<{}> = ({}) => (
  <img
    className="elevator-status__closure-you-are-here-icon"
    src={imagePath("elevator-status-you-are-here.svg")}
  />
);

const RouteModeIcons: ComponentType<{ icons: Icon[] }> = ({ icons }) => (
  <>
    {icons.map((icon) => (
      <img
        key={icon}
        className="elevator-status__closure-route-mode-icon"
        src={imagePath(`elevator-status-${icon}.svg`)}
      />
    ))}
  </>
);

const TimeframeHeadingIcon = ({
  happeningNow,
}: {
  happeningNow: boolean;
}): JSX.Element =>
  happeningNow ? (
    <img
      className="detail-page__closure-alert-icon"
      src={imagePath("elevator-status-alert-black.svg")}
    />
  ) : (
    <img
      className="detail-page__closure-alert-icon"
      src={imagePath("elevator-status-alert-gray.svg")}
    />
  );

const getTimeframeEndText = (
  happeningNow: boolean,
  activePeriod: ActivePeriod
) => {
  let endText: String = "";
  if (happeningNow) {
    if (activePeriod.end === null) {
      endText = "Until further notice";
    } else {
      const endDate = moment(activePeriod.end).tz("America/New_York");

      if (endDate.date() === moment().tz("America/New_York").date()) {
        endText = "Until later today";
      } else {
        endText = `Until ${endDate.format("MMM D")}`;
      }
    }
  } else {
    const startDate = moment(activePeriod.start).tz("America/New_York");
    if (activePeriod.end === null) {
      endText = `Starting ${startDate.format("MMM D")}`;
    } else {
      const endDate = moment(activePeriod.end).tz("America/New_York");
      if (startDate.month() === endDate.month()) {
        if (startDate.day() === endDate.day()) {
          endText = `${startDate.format("MMM D")}`;
        } else {
          endText = `${startDate.format("MMM D")}-${endDate.format("D")}`;
        }
      } else {
        endText = `${startDate.format("MMM D")} - ${endDate.format("MMM D")}`;
      }
    }
  }

  return endText;
};

const DetailPageComponent: ComponentType<DetailPage> = ({
  station: {
    is_at_home_stop: isAtHomeStop,
    name,
    icons,
    elevator_closures: [
      {
        header_text: headerText,
        description,
        timeframe: { happening_now: happeningNow, active_period: activePeriod },
      },
    ],
  },
}) => {
  return (
    <div className="detail-page">
      <div
        className={classWithModifier(
          "detail-page__closure",
          isAtHomeStop && happeningNow ? "active-at-home" : ""
        )}
      >
        <div className="detail-page__closure-location">
          <div className="detail-page__closure-outage-icon-container">
            <LocationHeadingIcon
              isAtHomeStop={isAtHomeStop}
              happeningNow={happeningNow}
            />
          </div>
          <div className="detail-page__closure-location-text">
            {isAtHomeStop ? "At this station" : name}
          </div>
          <div className="detail-page__closure-route-mode-here-icon-container">
            {isAtHomeStop ? <HereIcon /> : <RouteModeIcons icons={icons} />}
          </div>
        </div>
        <div className="detail-page__closure-header">{headerText}</div>
        <div className={"detail-page__timeframe"}>
          <div className="detail-page__closure-alert-icon-container">
            <TimeframeHeadingIcon happeningNow={happeningNow} />
          </div>
          <div className="detail-page__timeframe-text-start">
            {happeningNow ? "NOW" : "Upcoming"}
          </div>
          <div className="detail-page__timeframe-text-end">
            {getTimeframeEndText(happeningNow, activePeriod)}
          </div>
        </div>
        <div className="detail-page__description">{description}</div>
      </div>
    </div>
  );
};

const ListPageComponent: ComponentType<ListPage> = ({ stations }) => {
  return (
    <div className="elevator-status__list-view">
      {stations.map((station) => (
        <StationRow {...station} key={station.name} />
      ))}
    </div>
  );
};

const StationRow: ComponentType<Station> = ({
  name,
  icons,
  elevator_closures: elevatorClosures,
  is_at_home_stop: isAtHomeStop,
}) => {
  let rowClass = "elevator-status__station-row";
  if (isAtHomeStop) {
    rowClass += " elevator-status__station-row--home-stop";
  }

  return (
    <div className={rowClass}>
      <div className="elevator-status__station-row__header">
        <div className="elevator-status__station-row__icons">
          <RouteModeIcons icons={icons} />
        </div>
        <div className="elevator-status__station-row__station-name">{name}</div>
        <div className="elevator-status__station-row__ids">
          {formatElevatorIds(elevatorClosures.map(({ elevator_id: id }) => id))}
        </div>
        {isAtHomeStop && (
          <div className="elevator-status__station-row__you-are-here-icon">
            <HereIcon />
          </div>
        )}
      </div>
      <div className="elevator-status__station-row__closures">
        {elevatorClosures.map(({ elevator_name, elevator_id }) => (
          <div
            className="elevator-status__station-row__closure"
            key={elevator_id}
          >
            {elevator_name}
          </div>
        ))}
      </div>
    </div>
  );
};

const formatElevatorIds = (ids: string[]) => {
  switch (ids.length) {
    case 0:
      return "";
    case 1:
      return `#${ids[0]}`;
    case 2:
      return `#${ids[0]} and ${ids[1]}`;
    default:
      // a, b, ..., m, and n
      const allButLast = ids.slice(0, ids.length - 1);
      const last = ids[ids.length - 1];
      return `#${allButLast.join(", ")}, and ${last}`;
  }
};

export default makePersistentCarousel(ElevatorStatus);
