import React, { ComponentType } from "react";
import HandWithPhone from "Images/hand-with-phone.svg";

const BottomScreenFiller: ComponentType = () => (
  <div className="bottom-screen-filler">
    <div className="bottom-screen-filler__alternatives-container">
      <div className="bottom-screen-filler__alternatives__message">
        For real-time service alerts and updates, go to{" "}
      </div>
      <div className="bottom-screen-filler__alternatives__link-app">
        <span className="bottom-screen-filler__alternatives__message__em">
          mbta.com/schedules
        </span>{" "}
      </div>
    </div>
    <div className="bottom-screen-filler__phone-image-container">
      <HandWithPhone
        width="184px"
        height="283px"
        className="bottom-screen-filler__phone-image"
      />
    </div>
  </div>
);

export default BottomScreenFiller;
