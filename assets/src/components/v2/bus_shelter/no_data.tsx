import NoConnection from "Components/v2/bundled_svg/no_connection";
import Phone from "Components/v2/bundled_svg/phone";
import React, { ComponentType } from "react";

interface Props {
  show_alternatives: boolean;
}

const coolBlack = "#171F26";

const NoData: ComponentType<Props> = ({
  show_alternatives: showAlternatives,
}) => {
  return (
    <div className="no-data-container">
      <div className="no-data__main-content">
        <div className="no-data__main-content__no-connection-icon-container">
          <NoConnection
            className="no-data__main-content__no-connection-icon"
            colorHex={coolBlack}
          />
        </div>
        <div className="no-data__main-content__heading">
          Live updates are temporarily unavailable.
        </div>
        <div className="no-data__main-content__subheading">
          Thank you for your patience.
        </div>
      </div>
      {showAlternatives && (
        <>
          <div className="no-data__hairline" />
          <div className="no-data__alternatives-container">
            <div className="no-data__phone-icon-container">
              <Phone className="no-data__phone-icon" colorHex={coolBlack} />
            </div>
            <div className="no-data__alternatives__message">
              For schedules, go to{" "}
              <span className="no-data__alternatives__message__em">
                mbta.com/schedules
              </span>{" "}
              or{" "}
              <span className="no-data__alternatives__message__em">
                Transit
              </span>{" "}
              app
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default NoData;
