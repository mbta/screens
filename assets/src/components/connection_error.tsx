import React from "react";

const ConnectionError = (): JSX.Element => {
  return (
    <div className="connection-error">
      <div className="connection-error__top">
        <img
          className="connection-error__top-icon connection-error__top-icon--logo"
          src="images/logo-white.svg"
        />
        <div className="connection-error__top-text connection-error__top-text--white">
          Please excuse us
        </div>
      </div>
      <div className="connection-error__middle">
        <img
          className="connection-error__top-icon connection-error__top-icon--no-data"
          src="images/live-data-none.svg"
        />
        <div className="connection-error__top-text connection-error__top-text--black">
          Live updates are temporarily unavailable.
        </div>
      </div>
      <div className="connection-error__bottom">
        <div className="connection-error__bottom-logo"></div>
        <div className="connection-error__bottom-text">
          <div className="connection-error__bottom-text-description">
            Get real time predictions and stop info on your phone
          </div>
          <div className="connection-error__bottom-text-mbta-link">
            www.mbta.com/schedules
          </div>
          <div className="connection-error__bottom-text-transit-link">
            www.transitapp.com
          </div>
        </div>
      </div>
    </div>
  );
};

export default ConnectionError;
