import React from "react";
import { imagePath, classWithModifier } from "Util/util";
import {
  Departure,
  Direction,
  StationService,
} from "Components/v2/cr_departures/cr_departures";
import CRDepartureTime from "Components/v2/cr_departures/cr_departure_time";
import Arrow, { Direction as ArrowDirection } from "Components/v2/arrow";

interface Props {
  departures: Departure[];
  direction: Direction;
}

const DeparturesTable: React.ComponentType<Props> = ({
  departures,
  direction,
}) => {
  const getArrowOrTbd = (arrow: string) => {
    if (arrow) {
      return (
        <div className="arrow-image">
          <Arrow
            direction={arrow as ArrowDirection}
            className="departure__arrow-image"
          />
        </div>
      );
    }

    return <div className="track-tbd">TBD</div>;
  };

  const getStationServiceList = (stationServiceList: StationService[]) => {
    return stationServiceList.map((station: StationService) => (
      <div className="stops-at-text" key={station.name}>
        <div className="via-service-icon">
          <img
            src={imagePath(
              station.service ? "cr-service.svg" : "cr-no-service.svg",
            )}
          />
        </div>
        <div className="via-stop-name">{station.name}</div>
      </div>
    ));
  };

  return (
    <table className="cr-departures-table">
      <tbody>
        <tr>
          <th className="track">Track</th>
          <th className="headsign">Upcoming {direction} departures</th>
          <th className="arrival"></th>
        </tr>
        {departures.map((departure: Departure) => {
          const withStations =
            departure.headsign.station_service_list.length > 0
              ? "with-stations"
              : "";

          return (
            <tr key={departure.prediction_or_schedule_id}>
              <td className={`track ${withStations}`}>
                {getArrowOrTbd(departure.arrow)}
                {departure.track_number && (
                  <div className="track-number-text">
                    {departure.track_number}
                  </div>
                )}
              </td>
              <td className={`headsign ${withStations}`}>
                <div className="headsign-text">
                  {departure.headsign.headsign}
                </div>
                {getStationServiceList(departure.headsign.station_service_list)}
              </td>
              <td className={`arrival ${withStations}`}>
                <div
                  className={classWithModifier(
                    "departure-time",
                    departure.time.departure_type === "prediction" &&
                      departure.time.departure_time.type === "text"
                      ? "animated"
                      : "static",
                  )}
                >
                  <CRDepartureTime
                    departureType={departure.time.departure_type}
                    time={departure.time.departure_time}
                    isDelayed={departure.time.is_delayed}
                  />
                </div>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
};

export default DeparturesTable;
