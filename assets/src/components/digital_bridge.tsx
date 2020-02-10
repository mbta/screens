import QRCode from "qrcode.react";
import React from "react";

const DigitalBridge = ({ stopId }): JSX.Element => {
  return (
    <div className="digital-bridge-container">
      <div className="digital-bridge-logo-container">
        <img
          className="digital-bridge-logo-image"
          src="images/logo-white.svg"
        />
      </div>
      <div className="digital-bridge-link-container">
        <div className="digital-bridge-link-description">
          Real time predictions and stop info on the go
        </div>
        <div className="digital-bridge-link-url">
          www.mbta.com/stops/{stopId}
        </div>
      </div>
      <div className="digital-bridge-qr-container">
        <div className="digital-bridge-qr-image-container">
          <QRCode
            className="digital-bridge-qr-image"
            size={112}
            value={"www.mbta.com/stops/" + stopId}
          />
        </div>
      </div>
    </div>
  );
};

export default DigitalBridge;
