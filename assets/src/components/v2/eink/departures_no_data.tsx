import React, { ComponentType } from "react";
import NoConnection from "Components/v2/bundled_svg/no_connection";

interface Props {
  show_alternatives: boolean;
  stop_id: string;
}

const coolBlack = "#171F26";

const DeparturesNoData: ComponentType<Props> = ({
  show_alternatives: showAlternatives,
  stop_id: stopId,
}) => {
  return (
    <div className="departures-no-data-container">
      <div className="departures-no-data__main-content">
        <div className="departures-no-data__main-content__no-connection-icon-container">
          <NoConnection
            className="departures-no-data__main-content__no-connection-icon"
            colorHex={coolBlack}
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
