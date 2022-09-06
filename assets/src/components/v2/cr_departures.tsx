import BaseDepartureTime from "Components/eink/base_departure_time";
import Arrow, { Direction } from "Components/solari/arrow";
import React from "react";
import { classWithModifier, imagePath } from "Util/util";
import CRIcon from "./bundled_svg/cr_icon";
import Free from "./bundled_svg/free";
import ClockIcon from "./clock_icon";

interface StationService {
  name: string;
  service: boolean;
}
interface Departure {
  arrow: string;
  headsign: {
    headsign: string;
    station_service_list: StationService[];
  };
  time: any;
  track_number: number;
  prediction_or_schedule_id: string;
}
interface CRDeparturesProps {
  departures: Departure[];
  destination: string;
  time_to_destination: string;
  overnight_asset_url: string;
}

const DeparturesTable: React.ComponentType<any> = (props) => {
  const { departures } = props;

  const getArrowOrTbd = (arrow: string) => {
    if (arrow) {
      return (
        <div className="arrow-image">
          <Arrow
            direction={arrow as Direction}
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

  return (
    <table>
      <tbody>
        <tr>
          <td className="track">
            <div className="table-header__english">Track</div>
            <div className="table-header__spanish">Pista</div>
          </td>
          <td className="headsign">
            <div className="table-header__english">Upcoming departures</div>
            <div className="table-header__spanish">Próximas salidas</div>
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

const CRDepartures: React.ComponentType<CRDeparturesProps> = (props) => {
  const { departures, destination, time_to_destination, overnight_asset_url } =
    props;

  let maxMinutes = parseInt(time_to_destination.split("-")[1]);
  if (isNaN(maxMinutes)) {
    maxMinutes = 15;
  }

  return (
    <div className="departures-container">
      <div className="departures-card">
        <div className="departures-card__header">
          <CRIcon className="commuter-rail-icon" colorHex="#d9d6d0" />
          <div className="departures-card__header-text">
            <div className="departures-card__header-text-english">
              Commuter Rail
            </div>
            <div className="departures-card__header-text-spanish">
              Tren de Cercanías
            </div>
          </div>
        </div>
        {departures.length ? (
          <div className="departures-card__body">
            <DeparturesTable departures={departures} />
          </div>
        ) : (
          <div>
            <img
              className="departures-card__overnight-image"
              src={overnight_asset_url}
            />
          </div>
        )}
        <div className="departures-card__footer">
          <div className="departures-card__info-row">
            <div className="small-svg clock-icon">
              <ClockIcon
                minutes={maxMinutes}
                fgColor="rgb(23, 31, 38)"
                bgColor="transparent"
              />
            </div>
            <div className="departures-card__time-to-destination">
              <span className="departures-card__footer-english time-to-destination">
                {time_to_destination}m to {destination}
              </span>
              <span className="departures-card__footer-spanish time-to-destination">
                paseo a {destination}
              </span>
            </div>
          </div>
          <div className="departures-card__info-row">
            <div className="free-cr">
              <Free className="small-svg" colorHex="#00843d" />
            </div>
            <div className="departures-card__footer-ride-free">
              <div className="departures-card__footer-english ride-free">
                Show your Charlie Card or Charlie Ticket to ride free of charge
              </div>
              <div className="departures-card__footer-spanish ride-free">
                Viajar gratis
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CRDepartures;
