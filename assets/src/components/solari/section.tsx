import React from "react";

import Departure from "Components/solari/departure";
import Arrow from "Components/solari/arrow";

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

  render() {
    const currentPagedDeparture = this.props.departures[this.state.index];

    return (
      <div className="section">
        {this.props.showSectionHeaders && (
          <SectionHeader name={this.props.name} arrow={this.props.arrow} />
        )}
        <div className="departure-container">
          {this.props.departures
            .slice(0, this.props.numRows - 1)
            .map(
              ({
                id,
                route,
                destination,
                time,
                route_id: routeId,
                vehicle_status: vehicleStatus,
                alerts: alerts,
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
                    key={id}
                  />
                );
              }
            )}

          {currentPagedDeparture && (
            <>
              <div className="section__later-departure-header">
                Later Departures from {this.props.name}
              </div>
              <Departure
                route={currentPagedDeparture.route}
                routeId={currentPagedDeparture.route_id}
                destination={currentPagedDeparture.destination}
                time={currentPagedDeparture.time}
                currentTimeString={this.props.currentTimeString}
                vehicleStatus={currentPagedDeparture.vehicle_status}
                alerts={currentPagedDeparture.alerts}
              />
            </>
          )}
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
