import React, { ReactElement } from "react";

import { classWithModifier } from "Util/util";
import { NormalHeaderTime } from "./normal_header";

import Logo from "../../../static/images/svgr_bundled/logo.svg";
import ArrowUp from "../../../static/images/svgr_bundled/Arrow-90.svg";
import ArrowUpLeft from "../../../static/images/svgr_bundled/Arrow-45.svg";

import KeyNotCrowded from "../../../static/images/svgr_bundled/train_crowding/Car-NotCrowded-Key.svg";
import KeySomeCrowding from "../../../static/images/svgr_bundled/train_crowding/Car-SomeCrowding-Key.svg";
import KeyCrowded from "../../../static/images/svgr_bundled/train_crowding/Car-Crowded-Key.svg";
import KeyNoData from "../../../static/images/svgr_bundled/train_crowding/Car-NoData-Key.svg";
import KeyClosed from "../../../static/images/svgr_bundled/train_crowding/Car-Closed-Key.svg";

import CarNotCrowdedLeft from "../../../static/images/svgr_bundled/train_crowding/Car-NotCrowded-Left.svg";
import CarSomeCrowdingLeft from "../../../static/images/svgr_bundled/train_crowding/Car-SomeCrowding-Left.svg";
import CarCrowdedLeft from "../../../static/images/svgr_bundled/train_crowding/Car-Crowded-Left.svg";
import CarNoDataLeft from "../../../static/images/svgr_bundled/train_crowding/Car-NoData-Left.svg";
import CarClosedLeft from "../../../static/images/svgr_bundled/train_crowding/Car-Closed-Left.svg";

import CarNotCrowdedMiddle from "../../../static/images/svgr_bundled/train_crowding/Car-NotCrowded-Middle.svg";
import CarSomeCrowdingMiddle from "../../../static/images/svgr_bundled/train_crowding/Car-SomeCrowding-Middle.svg";
import CarCrowdedMiddle from "../../../static/images/svgr_bundled/train_crowding/Car-Crowded-Middle.svg";
import CarNoDataMiddle from "../../../static/images/svgr_bundled/train_crowding/Car-NoData-Middle.svg";
import CarClosedMiddle from "../../../static/images/svgr_bundled/train_crowding/Car-Closed-Middle.svg";

import CarNotCrowdedRight from "../../../static/images/svgr_bundled/train_crowding/Car-NotCrowded-Right.svg";
import CarSomeCrowdingRight from "../../../static/images/svgr_bundled/train_crowding/Car-SomeCrowding-Right.svg";
import CarCrowdedRight from "../../../static/images/svgr_bundled/train_crowding/Car-Crowded-Right.svg";
import CarNoDataRight from "../../../static/images/svgr_bundled/train_crowding/Car-NoData-Right.svg";
import CarClosedRight from "../../../static/images/svgr_bundled/train_crowding/Car-Closed-Right.svg";

interface Props {
  arrivalTime: string;
  crowding: string[];
  destination: string;
  front_car_direction: string;
  now: string;
  platform_position: number;
}

const lookupCarComponent = (
  occupancyStatus: string,
  frontCarDirection: string | boolean,
) => {
  if (frontCarDirection) {
    if (occupancyStatus == "not_crowded")
      return frontCarDirection == "left"
        ? CarNotCrowdedLeft
        : CarNotCrowdedRight;
    else if (occupancyStatus == "some_crowding")
      return frontCarDirection == "left"
        ? CarSomeCrowdingLeft
        : CarSomeCrowdingRight;
    else if (occupancyStatus == "crowded")
      return frontCarDirection == "left" ? CarCrowdedLeft : CarCrowdedRight;
    else if (occupancyStatus == "closed")
      return frontCarDirection == "left" ? CarClosedLeft : CarClosedRight;
    else return frontCarDirection == "left" ? CarNoDataLeft : CarNoDataRight;
  } else {
    if (occupancyStatus == "not_crowded") return CarNotCrowdedMiddle;
    else if (occupancyStatus == "some_crowding") return CarSomeCrowdingMiddle;
    else if (occupancyStatus == "crowded") return CarCrowdedMiddle;
    else if (occupancyStatus == "closed") return CarClosedMiddle;
    else return CarNoDataMiddle;
  }
};

const TrainCrowding: React.ComponentType<Props> = ({
  crowding,
  destination,
  platform_position,
  front_car_direction,
  now,
}) => {
  // If the front car direction is right, the crowding array needs to be reversed
  // so the last car is rendered on the left.
  const trains = crowding.map((car, i) => {
    const CarComponent = lookupCarComponent(car, i == 0 && front_car_direction);
    return <CarComponent key={i} className="crowding-widget__train-car" />;
  });

  const trainSequence =
    front_car_direction == "left"
      ? trains
      : ([] as ReactElement[]).concat(trains).reverse();

  // If arrow is between screens, scoot the arrow to the next slot on the right
  const arrowSlot = [1, 9, 17].includes(platform_position)
    ? platform_position + 1
    : platform_position == 25
    ? platform_position - 1
    : platform_position;

  // The slot arrangement exceeds the edges of the screen, so to properly set the slot positions
  // we need to make a few adjustments.
  const screenWidth = 3240;
  const slotOverhang = 35;
  const slotsWidth = screenWidth + slotOverhang * 2;
  const extraArrowPadding = 24;
  const arrowLeftPadding =
    (arrowSlot - 1) * (slotsWidth / 25) - slotOverhang - extraArrowPadding;
  const arrowDirection = [1, 9, 17].includes(platform_position)
    ? "up-left"
    : platform_position == 25
    ? "up-right"
    : "up";

  const textPane = Math.floor((arrowSlot / 25) * 3);
  const textPadding = (textPane * 3240) / 3;

  return (
    <div className="crowding-widget">
      <div className="crowding-widget__header">
        <div className="crowding-widget__header__top-row">
          <Logo width="128" height="128" color="#E5E4E1" className="t-logo" />
          {now && <NormalHeaderTime time={now} />}
        </div>
        <div className="crowding-widget__header__destination-sentence">
          Next train to<span className="destination">{destination}</span>
        </div>
      </div>
      <div className="crowding-widget__body">
        <div className="crowding-widget__train-row">{trainSequence}</div>
        <div style={{ paddingLeft: arrowLeftPadding }}>
          {arrowDirection == "up" ? (
            <ArrowUp
              className={classWithModifier(
                "crowding-widget__you-are-here-arrow",
                arrowDirection,
              )}
            />
          ) : (
            <ArrowUpLeft
              className={classWithModifier(
                "crowding-widget__you-are-here-arrow",
                arrowDirection,
              )}
            />
          )}
        </div>
        <div
          style={{ marginLeft: textPadding }}
          className={classWithModifier(
            "crowding-widget__you-are-here-text",
            [8, 16, 24].includes(arrowSlot) ? "right-align" : "left-align",
          )}
        >
          You are here
        </div>
      </div>
      <div className="crowding-widget__footer">
        <div className="crowding-widget__footer__segment">
          Current crowding on board
        </div>
        <div className="crowding-widget__footer__segment">
          <div className="crowding-widget__footer__key-row">
            <KeyNotCrowded width="137" height="100" className="key-icon" /> Not
            crowded
          </div>
          <div className="crowding-widget__footer__key-row">
            <KeySomeCrowding width="137" height="100" className="key-icon" />{" "}
            Some crowding
          </div>
        </div>
        <div className="crowding-widget__footer__segment">
          <div className="crowding-widget__footer__key-row">
            <KeyCrowded width="137" height="100" className="key-icon" /> Crowded
          </div>
          <div className="crowding-widget__footer__key-row">
            {crowding.includes("closed") ? (
              <>
                <KeyClosed width="137" height="100" className="key-icon" />{" "}
                Closed
              </>
            ) : (
              crowding.includes("no_data") && (
                <>
                  <KeyNoData width="137" height="100" className="key-icon" /> No
                  Data
                </>
              )
            )}
          </div>
        </div>
      </div>
      <div
        style={{
          borderLeft: "1px solid black",
          height: 1920,
          marginLeft: 1080,
          position: "absolute",
          top: 0,
          bottom: 0,
        }}
      ></div>
      <div
        style={{
          borderLeft: "1px solid black",
          height: 1920,
          marginLeft: 2160,
          position: "absolute",
          top: 0,
          bottom: 0,
        }}
      ></div>
    </div>
  );
};

export default TrainCrowding;
