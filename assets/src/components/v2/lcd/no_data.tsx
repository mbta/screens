import NoConnection from "Components/v2/bundled_svg/no_connection";
import React, { ComponentType } from "react";
import TLogo from "Components/v2/bundled_svg/t_logo";

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
            <div className="no-data__alternatives__message">
              For schedules, go to{" "}
              <span className="no-data__alternatives__message__em">
                mbta.com/schedules
              </span>{" "}
            </div>
            <div className="no-data__t-logo-icon-container">
              <TLogo className="no-data__t-logo-icon" colorHex={coolBlack} />
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default NoData;
