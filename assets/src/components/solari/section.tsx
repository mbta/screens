import React from "react";

import Departure from "Components/solari/departure";
import Arrow from "Components/solari/arrow";

import { classWithModifiers } from "Util/util";

const SectionHeader = ({ name, arrow }): JSX.Element => {
  return (
    <div className="section-header">
      <span className="section-header__name">{name}</span>
      <span className="section-header__arrow-container">
        {arrow !== null && (
          <Arrow direction={arrow} className="section-header__arrow-image" />
        )}
      </span>
    </div>
  );
};

const RoutePill = ({ route, selected }): JSX.Element => {
  const selectedModifier = selected ? "selected" : "unselected";
  const slashModifier = route.includes("/") ? "with-slash" : "no-slash";
  const modifiers = [selectedModifier, slashModifier];
  const pillClass = classWithModifiers(
    "later-departure__route-pill",
    modifiers
  );
  const textClass = classWithModifiers(
    "later-departure__route-text",
    modifiers
  );

  return (
    <div className={pillClass}>
      <div className={textClass}>{route}</div>
    </div>
  );
};

const PagedDeparture = ({
  departures,
  currentPageNumber,
  currentTimeString,
}): JSX.Element => {
  const currentPagedDeparture = departures[currentPageNumber];

  if (!currentPagedDeparture) {
    return null;
  }

  return (
    <div className="later-departure">
      <div className="later-departure__header">
        <div className="later-departure__header-title">Later Departures</div>
        <div className="later-departure__header-route-list">
          {departures.map((departure, i) => (
            <RoutePill
              route={departure.route}
              selected={i === currentPageNumber}
              key={departure.id}
            />
          ))}
        </div>
      </div>
      <Departure
        route={currentPagedDeparture.route}
        routeId={currentPagedDeparture.route_id}
        destination={currentPagedDeparture.destination}
        time={currentPagedDeparture.time}
        currentTimeString={currentTimeString}
        vehicleStatus={currentPagedDeparture.vehicle_status}
        alerts={[] /* don't show alerts in the scrolling row */}
        stopType={currentPagedDeparture.stopType}
      />
    </div>
  );
};

class PagedSection extends React.Component {
  constructor(props) {
    super(props);
    this.state = { index: props.numRows - 1 };
    this.MAX_PAGE_COUNT = 5;
  }

  componentDidMount() {
    this.interval = setInterval(
      this.updatePaging.bind(this),
      this.pageDuration()
    );
  }

  componentWillUnmount() {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  updatePaging() {
    this.setState((state, props) => {
      const maxIndex = this.pageCount(props) + props.numRows - 2;
      return { index: Math.min(maxIndex, state.index + 1) };
    });
  }

  pageCount(props) {
    const excessDepartures = props.departures.length - props.numRows + 1;
    return Math.min(excessDepartures, this.MAX_PAGE_COUNT);
  }

  pageDuration() {
    const numPages = this.pageCount(this.props);
    if (numPages <= 1) {
      return 15000;
    } else if (numPages === 2) {
      return 3750;
    } else {
      return 15000 / numPages;
    }
  }

  pagedRoutes() {
    return this.pagedDepartures().map(({ route }) => route);
  }

  pagedDepartures() {
    const startIndex = this.props.numRows - 1;
    const pageCount = this.pageCount(this.props);
    return this.props.departures.slice(startIndex, startIndex + pageCount);
  }

  currentPageNumber() {
    return this.state.index - (this.props.numRows - 1);
  }

  render() {
    const staticDepartures = this.props.departures.slice(
      0,
      this.props.numRows - 1
    );
    return (
      <div className="section">
        {this.props.showSectionHeaders && (
          <SectionHeader name={this.props.name} arrow={this.props.arrow} />
        )}
        <div className="departure-container">
          {staticDepartures.map(
            ({
              id,
              route,
              destination,
              time,
              route_id: routeId,
              vehicle_status: vehicleStatus,
              alerts: alerts,
              stop_type: stopType,
            }) => {
              return (
                <Departure
                  route={route}
                  routeId={routeId}
                  destination={destination}
                  time={time}
                  currentTimeString={this.props.currentTimeString}
                  vehicleStatus={vehicleStatus}
                  alerts={alerts}
                  stopType={stopType}
                  key={id}
                />
              );
            }
          )}
          <PagedDeparture
            departures={this.pagedDepartures()}
            currentPageNumber={this.currentPageNumber()}
            currentTimeString={this.props.currentTimeString}
          />
        </div>
      </div>
    );
  }
}

const Section = ({
  name,
  arrow,
  departures,
  showSectionHeaders,
  currentTimeString,
  paging,
  numRows,
}): JSX.Element => {
  return (
    <div className="section">
      {showSectionHeaders && <SectionHeader name={name} arrow={arrow} />}
      <div className="departure-container">
        {departures
          .slice(0, numRows)
          .map(
            ({
              id,
              route,
              destination,
              time,
              route_id: routeId,
              vehicle_status: vehicleStatus,
              alerts,
              stop_type: stopType,
            }) => {
              return (
                <Departure
                  route={route}
                  routeId={routeId}
                  destination={destination}
                  time={time}
                  currentTimeString={currentTimeString}
                  vehicleStatus={vehicleStatus}
                  alerts={alerts}
                  stopType={stopType}
                  key={id}
                />
              );
            }
          )}
      </div>
    </div>
  );
};

export { PagedSection, Section };
