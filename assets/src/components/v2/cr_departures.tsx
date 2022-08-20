import BaseDepartureTime from "Components/eink/base_departure_time";
import Arrow from "Components/solari/arrow";
import useInterval from "Hooks/use_interval";
import React, { useState } from "react";
import { classWithModifier, imagePath } from "Util/util";
import CRIcon from "./bundled_svg/cr_icon";
import Free from "./bundled_svg/free";
import ClockIcon from "./clock_icon";

interface Departure {
  arrow: string;
  headsign: {
    headsign: string;
    variation: string;
  };
  time: any;
  track_number: number;
  prediction_or_schedule_id: string;
}
interface CRDeparturesProps {
  departures: Departure[];
  destination: string;
  time_to_destination: string;
  show_via_headsigns_message: boolean;
}

const DeparturesTable: React.ComponentType<any> = (props) => {
  const { departures } = props;

  let [headsignPageOne, setHeadsignPageOne] = useState(true);

  useInterval(() => {
    setHeadsignPageOne(!headsignPageOne);
  }, 4000);

  return (
    <table>
      <tbody>
        <tr>
          <td className="wayfinding-arrow-column"></td>
          <td className="headsign-column">
            <div className="table-header__english">Upcoming departures</div>
            <div className="table-header__spanish">Próximas salidas</div>
          </td>
          <td className="arrival-column"></td>
          <td className="track-column">
            <div className="table-header__english">Track</div>
            <div className="table-header__spanish">Pista</div>
          </td>
        </tr>
        {departures.slice(0, 3).map((departure) => {
          return (
            <tr key={departure.prediction_or_schedule_id}>
              <td>
                {departure.arrow ? (
                  <Arrow
                    direction={departure.arrow}
                    className="departure__arrow-image"
                  />
                ) : (
                  ""
                )}
              </td>
              {headsignPageOne ? (
                <td className="headsign">{departure.headsign.headsign}</td>
              ) : (
                <td className="headsign">{departure.headsign.variation ? "... "+departure.headsign.variation : departure.headsign.headsign}</td>
              )}
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
              <td className="track">{departure.track_number ?? ""}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
};

const CRDepartures: React.ComponentType<CRDeparturesProps> = (props) => {
  const {
    departures,
    destination,
    time_to_destination,
    show_via_headsigns_message,
  } = props;

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
        <div className="departures-card__body">
          <DeparturesTable departures={departures} />
          {show_via_headsigns_message ? (
            <div className="departures-card__info-row">
              <img className="small-svg" src={imagePath(`logo-black.svg`)} />
              <div className="departures-card__info-text">
                <div className="departures-card__body-english">
                  <strong>Trains via Ruggles</strong> stop at Ruggles, but{" "}
                  <strong>not</strong> Forest Hills
                </div>
                <div className="departures-card__body-spanish">
                  Trenes a través de Ruggles se detiene en Ruggles, pero no en
                  Forest Hills
                </div>
                <div className="departures-card__body-english">
                  <strong>Trains via Forest Hills</strong> stop at Ruggles and
                  Forest Hills
                </div>
                <div className="departures-card__body-spanish">
                  Trenes a través de Forest Hills paradas en Ruggles y Forest
                  Hills
                </div>
              </div>
            </div>
          ) : (
            <div className="departures-card__info-row">
              <img className="small-svg" src={imagePath(`logo-black.svg`)} />
              <div className="departures-card__info-text">
                <div className="departures-card__body-english">
                  <div>
                    All trains to <strong>South</strong> Station stop at
                  </div>
                  <div>
                    <strong>Ruggles</strong> and <strong>Back Bay</strong>
                  </div>
                </div>
                <div className="departures-card__body-spanish">
                  <div>Todos los trenes hacia South Station parán en</div>
                  <div>Ruggles y Back Bay.</div>
                </div>
              </div>
            </div>
          )}
        </div>
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
