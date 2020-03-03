import QRCode from "qrcode.react";
import React from "react";

const DigitalBridge = ({ stopId }): JSX.Element => {
  return (
    <div className="digital-bridge">
      <div className="digital-bridge__logo-container">
        <img
          className="digital-bridge__logo-image"
          src="/images/logo-white.svg"
        />
      </div>
      <div className="digital-bridge__link-container">
        <div className="digital-bridge__link-description">
          Real-time predictions and stop info on the go
        </div>
        <div className="digital-bridge__link-url">mbta.com/stops/{stopId}</div>
      </div>
      <div className="digital-bridge__qr-container">
        <div className="digital-bridge__qr-image-container">
          <QRCode
            className="digital-bridge__qr-image"
            size={112}
            value={
              "www.mbta.com/stops/" +
              stopId +
              "?utm_source=qr&utm_medium=eink&utm_campaign=einkbus"
            }
          />
        </div>
      </div>
    </div>
  );
};

export default DigitalBridge;
