import React from "react";
import CRDeparturesHeader from "Components/v2/cr_departures/cr_departures_header";
import DeparturesTable from "Components/v2/cr_departures/cr_departures_table";

type Direction = "inbound" | "outbound";
interface StationService {
  name: string;
  service: boolean;
}

interface DepartureTime {
  departure_type: "prediction" | "schedule";
  departure_time: any;
  is_delayed: boolean;
}

interface Departure {
  arrow: string;
  headsign: {
    headsign: string;
    station_service_list: StationService[];
  };
  time: DepartureTime;
  track_number: number;
  prediction_or_schedule_id: string;
}

interface CRDeparturesProps {
  departures: Departure[];
  destination: string;
  direction: Direction;
  header_pill: string;
}

const CRDepartures: React.ComponentType<CRDeparturesProps> = (props) => {
  const { departures, direction, header_pill } = props;

  return (
    <div className="departures-container">
      <div className="departures-card">
        <CRDeparturesHeader headerPill={header_pill} />
        <div className="departures-card__body">
          <DeparturesTable departures={departures} direction={direction} />
        </div>
      </div>
    </div>
  );
};

export { Departure, Direction, StationService };
export default CRDepartures;
