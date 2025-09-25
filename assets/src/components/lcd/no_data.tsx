import NoConnection from "Images/live-data-none.svg";
import type { ComponentType } from "react";
import TLogo from "Images/logo.svg";

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
            width="128"
            height="128"
            className="no-data__main-content__no-connection-icon"
            color={coolBlack}
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
              <TLogo
                width="1000"
                height="1000"
                className="no-data__t-logo-icon"
                color={coolBlack}
              />
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default NoData;
