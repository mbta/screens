import React, { ComponentType } from "react";
import NoConnection from "Images/live-data-none.svg";

interface Props {
  show_alternatives: boolean;
  stop_id: string;
}

const DeparturesNoData: ComponentType<Props> = ({
  show_alternatives: showAlternatives,
  stop_id: stopId,
}) => {
  return (
    <div className="departures-no-data-container">
      <div className="departures-no-data__main-content">
        <div className="departures-no-data__main-content__no-connection-icon-container">
          <NoConnection
            width="128"
            height="128"
            className="departures-no-data__main-content__no-connection-icon"
            color="#000000"
          />
        </div>
        <div className="departures-no-data__main-content__heading">
          Live departure updates are temporarily unavailable.
        </div>
      </div>
      {showAlternatives && (
        <>
          <div className="departures-no-data__hairline" />
          <div className="departures-no-data__alternatives-container">
            <div className="departures-no-data__alternatives__message">
              For schedules, go to{" "}
              <span className="departures-no-data__alternatives__message__em">
                mbta.com/stops/{stopId}
              </span>{" "}
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default DeparturesNoData;
