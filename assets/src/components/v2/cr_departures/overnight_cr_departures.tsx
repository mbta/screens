import React, { ComponentType } from "react";
import DeparturesTable from "Components/v2/cr_departures/cr_departures_table";
import CRDeparturesHeader from "Components/v2/cr_departures/cr_departures_header";
import OvernightMoon from "../bundled_svg/overnight_moon";
import moment from "moment";
import { imagePath } from "Util/util";

interface Props {
  direction: string;
  last_schedule_departure_time: string;
  last_schedule_headsign_stop: string;
  last_schedule_headsign_via: string;
  overnight_text_english: string;
  overnight_text_spanish: string;
}

const OvernightCRDepartures: ComponentType<Props> = ({
  direction,
  last_schedule_departure_time: lastScheduleDepartureTime,
  last_schedule_headsign_stop: lastScheduleHeadsignStop,
  last_schedule_headsign_via: lastScheduleHeadsignVia,
  overnight_text_english: overnightTextEnglish,
  overnight_text_spanish: overnightTextSpanish,
}) => {
  const getDirectionText = (language: string) => {
    if (direction === "inbound") {
      if (language === "english") {
        return "into Boston";
      }

      return "hacia Boston";
    } else if (direction === "outbound") {
      if (language === "english") {
        return direction;
      }

      return "que sale de Boston";
    }

    return "";
  };

  return (
    <div className="overnight-cr-departures__container">
      <div className="overnight-cr-departures__card">
        <CRDeparturesHeader />
        <div className="overnight-cr-departures__body">
          <DeparturesTable departures={[]} />
          <div className="overnight-cr-departures__body-text">
            <div className="overnight-cr-departures__body-text--english">
              {overnightTextEnglish}
            </div>
            <div className="overnight-cr-departures__body-text--spanish">
              {overnightTextSpanish}
            </div>
          </div>
        </div>
        <div className="overnight-cr-departures__footer">
          <OvernightMoon
            className="overnight-cr-departures__overnight-icon"
            colorHex="#262626"
          />
          <div className="overnight-cr-departures__last-train-text">
            <div className="overnight-cr-departures__last-train-text--english">
              Last train {getDirectionText("english")} tomorrow:
            </div>
            <div className="overnight-cr-departures__last-train-text--spanish">
              Último tren {getDirectionText("spanish")} mañana:
            </div>
          </div>
          <div className="overnight-cr-departures__schedule">
            <div className="overnight-cr-departures__schedule-departure-time-container">
              <div className="overnight-cr-departures__schedule-departure-time">
                {moment(lastScheduleDepartureTime).format("h:mm")}
              </div>
              <div className="overnight-cr-departures__schedule-departure-time-am-pm">
                {moment(lastScheduleDepartureTime).format("A")}
              </div>
            </div>
            <div className="overnight-cr-departures__schedule-headsign">
              <div className="overnight-cr-departures__schedule-headsign--stop">
                {lastScheduleHeadsignStop}
              </div>
              <div className="overnight-cr-departures__schedule-headsign--via">
                {lastScheduleHeadsignVia}
              </div>
            </div>
          </div>
          <div className="overnight-cr-departures__footer-hairline"></div>
          <img
            className="overnight-cr-departures__footer-cr-info-icon"
            src={imagePath(`logo-black.svg`)}
          />
          <div className="overnight-cr-departures__footer-cr-info">
            <div className="overnight-cr-departures__footer-cr-info--english">
              For full Commuter Rail schedules, see:
            </div>
            <div className="overnight-cr-departures__footer-cr-info--spanish">
              Para los horarios completos de Trenes de Cercanías, consulte:
            </div>
            <div className="overnight-cr-departures__footer-cr-info--url">
              mbta.com/schedules/commuter-rail
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OvernightCRDepartures;
