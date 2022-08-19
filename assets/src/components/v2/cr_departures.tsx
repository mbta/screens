import BaseDepartureTime from "Components/eink/base_departure_time";
import Arrow from "Components/solari/arrow";
import React from "react";
import { classWithModifier, imagePath } from "Util/util";
import CRIcon from "./bundled_svg/cr_icon";

interface CRDeparturesProps {
  departures: any,
  destination: string,
  time_to_destination: string
}

const CRDepartures: React.ComponentType<CRDeparturesProps> = (props) => {
  const { departures, destination, time_to_destination } = props
  console.log(props)
  
  return (
    <div className="departures-container">
      <div className="departures-card">
        <div className="departures-card__header">
          <CRIcon className="commuter-rail-icon" colorHex="#d9d6d0"/>
          <div className="departures-card__header-text">
            <div className="departures-card__header-text-english">Commuter Rail</div>
            <div className="departures-card__header-text-spanish">Tren de Cercanías</div>
          </div>
        </div>
        <div className="departures-card__body">
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
              { departures.slice(0, 3).map((departure, i) => {
                  return (
                    <tr key={i}>
                      <td>{departure.arrow ? <Arrow direction={departure.arrow} className="departure__arrow-image" /> : "" }</td>
                      {/* fix this so it flashes */}
                      <td className="headsign">{departure.headsign.headsign}</td>
                      <td className="arrival">
                        <div
                          className={classWithModifier("departure-time", departure.time.type === "text" ? "animated" : "static")}
                        >
                          <BaseDepartureTime time={departure.time} hideAmPm/>
                        </div>
                      </td>
                      <td className="track">{departure.track_number ? departure.track_number : ""}</td>
                    </tr>
                  )
              })}
            </tbody>
          </table>
          <div className="departures-card__info-row">
            <img
              className="small-svg"
              src={imagePath(`logo-black.svg`)}
            />
            <div className="departures-card__info-text">
              <div className="departures-card__body-english"><strong>Trains via Ruggles</strong> stop at Ruggles, but <strong>not</strong> Forest Hills</div>
              <div className="departures-card__body-spanish">Trenes a través de Ruggles se detiene en Ruggles, pero no en Forest Hills</div>
              <div className="departures-card__body-english"><strong>Trains via Forest Hills</strong> stop at Ruggles and Forest Hills</div>
              <div className="departures-card__body-spanish">Trenes a través de Forest Hills paradas en Ruggles y Forest Hills</div>
            </div>
          </div>
          
        </div>
        <div className="departures-card__footer">
          <div className="departures-card__info-row">
            <img
              className="small-svg"
              src={imagePath(`logo-black.svg`)}
            />
            <div className="departures-card__footer-english">{time_to_destination} to {destination}</div>
            <div className="departures-card__footer-spanish">paseo a {destination}</div>
          </div>
          <div className="departures-card__info-row">
            <img
              className="small-svg free-cr"
              src={imagePath(`free-cr.svg`)}
            />
            <div>
              <div className="departures-card__footer-english ride-free">
                Show your Charlie Card or Charlie Ticket to ride free of charge
              </div>
              <div className="departures-card__footer-spanish">
                Viajar gratis
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default CRDepartures;