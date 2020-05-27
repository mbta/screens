import React from "react";

import Departure from "Components/solari/departure";
import Arrow from "Components/solari/arrow";

import { classWithModifiers } from "Util/util";

const buildDepartureGroups = (departures) => {
  if (!departures) {
    return [];
  }

  const groups = [];

  departures.forEach((departure) => {
    if (groups.length === 0) {
      groups.push([departure]);
    } else {
      const currentGroup = groups[groups.length - 1];
      const {
        route_id: groupRoute,
        destination: groupDestination,
      } = currentGroup[0];
      const {
        route_id: departureRoute,
        destination: departureDestination,
      } = departure;
      if (
        groupRoute === departureRoute &&
        groupDestination === departureDestination
      ) {
        currentGroup.push(departure);
      } else {
        groups.push([departure]);
      }
    }
  });

  return groups;
};

const DepartureGroup = ({ departures, currentTimeString }): JSX.Element => {
  return (
    <div className="departure-group">
      {departures.map(
        (
          {
            id,
            route,
            destination,
            time,
            route_id: routeId,
            vehicle_status: vehicleStatus,
            alerts,
            stop_type: stopType,
          },
          i
        ) => {
          return (
            <Departure
              route={i === 0 ? route : null}
              routeId={routeId}
              destination={i === 0 ? destination : null}
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
  );
};

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
  if (currentPageNumber >= departures.length) {
    return null;
  }

  // Don't show alert badges in the paging row
  const currentPagedDeparture = {
    ...departures[currentPageNumber],
    alerts: [],
  };

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
      <DepartureGroup
        departures={[currentPagedDeparture]}
        currentTimeString={currentTimeString}
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

    const staticDepartureGroups = buildDepartureGroups(staticDepartures);

    return (
      <div className="section">
        {this.props.showSectionHeaders && (
          <SectionHeader name={this.props.name} arrow={this.props.arrow} />
        )}
        <div className="departure-container">
          {staticDepartureGroups.map((group) => (
            <DepartureGroup
              departures={group}
              currentTimeString={this.props.currentTimeString}
              key={group[0].id}
            />
          ))}
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
  departures = departures.slice(0, numRows);
  const departureGroups = buildDepartureGroups(departures);

  return (
    <div className="section">
      {showSectionHeaders && <SectionHeader name={name} arrow={arrow} />}
      <div className="departure-container">
        {departureGroups.map((group) => (
          <DepartureGroup
            departures={group}
            currentTimeString={currentTimeString}
            key={group[0].id}
          />
        ))}
      </div>
    </div>
  );
};

export { PagedSection, Section };
