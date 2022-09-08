import React from "react";
import Free from "Components/v2/bundled_svg/free";
import ClockIcon from "Components/v2/clock_icon";
import CRDeparturesHeader from "Components/v2/cr_departures/cr_departures_header";
import DeparturesTable from "Components/v2/cr_departures/cr_departures_table";

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
}

const CRDepartures: React.ComponentType<CRDeparturesProps> = (props) => {
  const { departures, destination, time_to_destination } = props;

  let maxMinutes = parseInt(time_to_destination.split("-")[1]);
  if (isNaN(maxMinutes)) {
    maxMinutes = 15;
  }

  return (
    <div className="departures-container">
      <div className="departures-card">
        <CRDeparturesHeader />
        <div className="departures-card__body">
          <DeparturesTable departures={departures} />
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
                Show your CharlieCard or CharlieTicket to ride at no charge
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

export { Departure, StationService };
export default CRDepartures;
