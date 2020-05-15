import React from "react";

import Departure from "Components/solari/departure";
import Arrow from "Components/solari/arrow";

const SectionHeader = ({ name, arrow, routeCount }): JSX.Element => {
  return (
    <div className="section-header">
      <span className="section-header__name">{name}</span>
      {arrow !== null ? (
        <span className="section-header__arrow-container">
          <Arrow direction={arrow} className="section-header__arrow-image" />
        </span>
      ) : (
        routeCount !== null && (
          <span className="section-header__route-count">{`${routeCount} routes`}</span>
        )
      )}
    </div>
  );
};

class PagedSection extends React.Component {
  constructor(props) {
    super(props);
    this.numStaticRows = props.paging.visible_rows - 1;
    this.state = { index: this.numStaticRows, departures: props.departures };
  }

  componentDidMount() {
    this.interval = setInterval(this.updatePaging.bind(this), 2000);
  }

  componentWillUnmount() {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  updatePaging() {
    if (!this.state.departures || this.state.departures.length === 0) {
      this.setState({ departures: this.props.departures });
    } else if (this.state.index === this.state.departures.length - 1) {
      // Reached end of list, update departures and restart paging
      this.setState({
        index: this.numStaticRows,
        departures: this.props.departures,
      });
    } else {
      this.setState({ index: this.state.index + 1 });
    }
  }

  render() {
    const currentPagedDeparture = this.state.departures[this.state.index];

    return (
      <div className="section">
        <SectionHeader
          name={this.props.name}
          arrow={this.props.arrow}
          routeCount={this.props.route_count}
        />
        <div className="departure-container">
          {this.state.departures
            .slice(0, this.numStaticRows)
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
  route_count: routeCount,
}): JSX.Element => {
  return (
    <div className="section">
      {showSectionHeaders && (
        <SectionHeader name={name} arrow={arrow} routeCount={routeCount} />
      )}
      <div className="departure-container">
        {departures.map(
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
