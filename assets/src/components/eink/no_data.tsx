import type { ComponentType } from "react";
import { imagePath } from "Util/utils";
import NoConnection from "Images/live-data-none.svg";
import BottomScreenFiller from "Components/eink/bottom_screen_filler";
import moment from "moment";

const NoData: ComponentType = () => {
  const currentTime = moment().tz("America/New_York").format("h:mm");

  return (
    <div className="no-data-container">
      <div className="no-data__top-screen">
        <div className="no-data__header">
          <div className="no-data__logo-container">
            <img
              className="no-data__logo-image"
              src={imagePath(`logo-white.svg`)}
            />
          </div>
          <div className="no-data__header-text-container">
            <div className="no-data__header-text">
              Thank you for your patience
            </div>
          </div>
          <div className="no-data__time">{currentTime}</div>
        </div>
        <div className="no-data__main-content">
          <div className="no-data__main-content__no-connection-icon-container">
            <NoConnection
              width="128"
              height="128"
              className="no-data__main-content__no-connection-icon"
              color="#000000"
            />
          </div>
          <div className="no-data__main-content__heading">
            Live updates are temporarily unavailable.
          </div>
          <div className="no-data__hairline" />
          <div className="no-data__main-content__subheading">
            Our apologies for the inconvenience.
          </div>
        </div>
      </div>
      <BottomScreenFiller />
    </div>
  );
};

export default NoData;
