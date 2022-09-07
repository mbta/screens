import React, { ComponentType } from "react";

interface Props {
  direction: string;
  last_schedule_departure_time: string;
  last_schedule_headsign: string;
}

const OvernightCRDepartures: ComponentType<Props> = ({
  direction,
  last_schedule_departure_time: lastScheduleDepartureTime,
  last_schedule_headsign: lastScheduleHeadsign,
}) => {
  return (
    <div className="overnight-cr-departures-container">
      <div className="overnight-cr-departures__header">{direction}</div>
      <div className="overnight-cr-departures__body">
        {lastScheduleDepartureTime}
      </div>
      <div className="overnight-cr-departures__footer">
        {lastScheduleHeadsign}
      </div>
    </div>
  );
};

export default OvernightCRDepartures;
