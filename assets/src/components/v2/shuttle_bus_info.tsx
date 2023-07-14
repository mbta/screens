import Arrow, { Direction } from "Components/solari/arrow";
import React, { ComponentType } from "react";
import { imagePath } from "Util/util";
import Accessible from "Components/v2/bundled_svg/accessible";
import Free from "Components/v2/bundled_svg/free";
import ClockIcon from "Components/v2/clock_icon";

interface Props {
  minutes_range_to_destination: string;
  destination: string;
  arrow: string;
  english_boarding_instructions: string;
  spanish_boarding_instructions: string;
}

const ShuttleBusInfo: ComponentType<Props> = ({
  minutes_range_to_destination: minutesRangeToDestination,
  destination,
  arrow,
  english_boarding_instructions: englighBoardingInstructions,
  spanish_boarding_instructions: spanishBoardingInstructions,
}) => {
  let maxMinutes = parseInt(minutesRangeToDestination.split("-")[1]);
  if (isNaN(maxMinutes)) {
    maxMinutes = 15;
  }

  return (
    <div className="shuttle-bus-info">
      <div className="shuttle-bus-info__container">
        <div className="shuttle-bus-info__header">
          <div className="shuttle-bus-info__header-icon-container">
            <img
              className="shuttle-bus-info__header-icon"
              src={imagePath("bus-negative-black.svg")}
            />
          </div>
          <div className="shuttle-bus-info__header-text">
            <div className="shuttle-bus-info__header-text--english">
              Shuttle Buses
            </div>
            <div className="shuttle-bus-info__header-text--spanish">
              Autobuses de enlace
            </div>
          </div>
        </div>
        <div className="shuttle-bus-info__boarding-instructions">
          <div className="shuttle-bus-info__boarding-instructions-arrow-icon-container">
            <Arrow
              direction={arrow as Direction}
              className="shuttle-bus-info__boarding-instructions-arrow-icon"
            />
          </div>
          <div className="shuttle-bus-info__boarding-instructions-text">
            <div className="shuttle-bus-info__boarding-instructions-text--english">
              {englighBoardingInstructions}
            </div>
            <div className="shuttle-bus-info__boarding-instructions-text--spanish">
              {spanishBoardingInstructions}
            </div>
          </div>
        </div>
        <div className="shuttle-bus-info__trip-info">
          <div className="shuttle-bus-info__trip-info-time">
            <div className="shuttle-bus-info__trip-info-time-icon-container">
              <ClockIcon
                minutes={maxMinutes}
                fgColor="rgb(23, 31, 38)"
                bgColor="transparent"
              />
            </div>
            <div className="shuttle-bus-info__trip-info-time-text">
              <span className="shuttle-bus-info__trip-info-time-text--english">{`${minutesRangeToDestination}m to ${destination}`}</span>
              <span className="shuttle-bus-info__trip-info-time-text--spanish">{`paseo a ${destination}`}</span>
            </div>
          </div>
          <div className="shuttle-bus-info__trip-info-price">
            <div className="shuttle-bus-info__trip-info-price-icon-container">
              <Free
                className="shuttle-bus-info__trip-info-price-icon"
                colorHex="#00843d"
              />
            </div>
            <div className="shuttle-bus-info__trip-info-price-text">
              <span className="shuttle-bus-info__trip-info-price-text--english">
                Free
              </span>
              <span className="shuttle-bus-info__trip-info-price-text--spanish">
                gratis
              </span>
            </div>
          </div>
          <div className="shuttle-bus-info__trip-info-accessibility">
            <div className="shuttle-bus-info__trip-info-accessibility-icon-container">
              <Accessible
                className="shuttle-bus-info__trip-info-accessibility-icon"
                colorHex="#165c96"
              />
            </div>
            <div className="shuttle-bus-info__trip-info-accessibility-text">
              <div className="shuttle-bus-info__trip-info-accessibility-text--english">
                All shuttle buses are accessible. Accessible vans also available
                upon request.
              </div>
              <div className="shuttle-bus-info__trip-info-accessibility-text--spanish">
                Todos los autobuses de enlace son accesibles. Microbuses
                accesibles estarán disponibles a su petición.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ShuttleBusInfo;
