import BaseDepartureTime from "Components/eink/base_departure_time";
import Arrow, { Direction as ArrowDirection } from "Components/solari/arrow";
import React from "react";
import { imagePath, classWithModifier } from "Util/util";
import {
  Departure,
  Direction,
  StationService,
} from "Components/v2/cr_departures/cr_departures";

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
    return stationServiceList.map((station: StationService) => {
      return (
        <div className="stops-at-text" key={station.name}>
          <div className="via-service-icon">
            <img
              src={imagePath(
                station.service ? "cr-service.svg" : "cr-no-service.svg"
              )}
            />
          </div>
          <div className="via-stop-name">{station.name}</div>
        </div>
      );
    });
  };

  const getHeaderDirection = (language: string) => {
    if (language === "english") {
      return direction;
    }

    if (direction === "inbound") {
      return "a";
    } else {
      return "que salen de";
    }
  };

  return (
    <table className="cr-departures-table">
      <tbody>
        <tr className="cr-departures-table__header-row">
          <td className="track">
            <div className="table-header__english">Track</div>
            <div className="table-header__spanish">Pista</div>
          </td>
          <td className="headsign">
            <div className="table-header__english">
              Upcoming {getHeaderDirection("english")} departures
            </div>
            <div className="table-header__spanish">
              Próximos {getHeaderDirection("spanish")} Boston
            </div>
          </td>
          <td className="arrival"></td>
        </tr>
        {departures.map((departure: Departure) => {
          return (
            <tr key={departure.prediction_or_schedule_id}>
              <td className="track">
                {getArrowOrTbd(departure.arrow)}
                <div className="track-number-text">
                  {departure.track_number}
                </div>
              </td>
              <td className="headsign">
                <div className="headsign-text">
                  {departure.headsign.headsign}
                </div>
                {getStationServiceList(departure.headsign.station_service_list)}
              </td>
              <td className="arrival">
                <div
                  className={classWithModifier(
                    "departure-time",
                    departure.time.type === "text" ? "animated" : "static"
                  )}
                >
                  <BaseDepartureTime time={departure.time} hideAmPm />
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
