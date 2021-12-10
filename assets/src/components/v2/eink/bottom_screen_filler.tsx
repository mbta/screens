import React, { ComponentType } from "react";
import HandWithPhone from "Components/v2/bundled_svg/hand_with_phone";

const BottomScreenFiller: ComponentType = () => (
  <div className="bottom-screen-filler">
    <div className="bottom-screen-filler__alternatives-container">
      <div className="bottom-screen-filler__alternatives__message">
        For the latest schedules and updates, go to{" "}
      </div>
      <div className="bottom-screen-filler__alternatives__link-app">
        <span className="bottom-screen-filler__alternatives__message__em">
          mbta.com/schedules
        </span>{" "}
        or{" "}
        <span className="bottom-screen-filler__alternatives__message__em">
          Transit
        </span>{" "}
        app
      </div>
    </div>
    <div className="bottom-screen-filler__phone-image-container">
      <HandWithPhone className="bottom-screen-filler__phone-image" />
    </div>
  </div>
);

export default BottomScreenFiller;
