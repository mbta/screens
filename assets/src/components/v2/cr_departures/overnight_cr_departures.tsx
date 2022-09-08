import React, { ComponentType } from "react";
import DeparturesTable from "Components/v2/cr_departures/cr_departures_table";
import CRDeparturesHeader from "Components/v2/cr_departures/cr_departures_header";

interface Props {
  direction: string;
  last_schedule_departure_time: string;
  last_schedule_headsign: string;
  overnight_text_english: string;
  overnight_text_spanish: string;
}

const OvernightCRDepartures: ComponentType<Props> = ({
  direction,
  last_schedule_departure_time: lastScheduleDepartureTime,
  last_schedule_headsign: lastScheduleHeadsign,
  overnight_text_english: overnightTextEnglish,
  overnight_text_spanish: overnightTextSpanish,
}) => {
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
          {lastScheduleHeadsign}
        </div>
      </div>
    </div>
  );
};

export default OvernightCRDepartures;
