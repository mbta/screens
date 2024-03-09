import React from "react";

import { classWithModifier } from "Util/util";
import { NormalHeaderTime } from "./normal_header";
import { usePlayerName } from "Hooks/outfront";
import { TRIPTYCH_VERSION } from "./triptych/version";

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

type FrontCarDirection = "left" | "right";
type OccupancyStatus =
  | "no_data"
  | "not_crowded"
  | "some_crowding"
  | "crowded"
  | "closed";

type CarOrientation = FrontCarDirection | "middle";
const lookupCarComponent = (
  occupancyStatus: OccupancyStatus,
  carOrientation: CarOrientation
) => {
  const lookupKey: `${CarOrientation}/${OccupancyStatus}` = `${carOrientation}/${occupancyStatus}`;

  switch (lookupKey) {
    case "left/not_crowded":
      return CarNotCrowdedLeft;
    case "left/some_crowding":
      return CarSomeCrowdingLeft;
    case "left/crowded":
      return CarCrowdedLeft;
    case "left/no_data":
      return CarNoDataLeft;
    case "left/closed":
      return CarClosedLeft;

    case "right/not_crowded":
      return CarNotCrowdedRight;
    case "right/some_crowding":
      return CarSomeCrowdingRight;
    case "right/crowded":
      return CarCrowdedRight;
    case "right/no_data":
      return CarNoDataRight;
    case "right/closed":
      return CarClosedRight;

    case "middle/not_crowded":
      return CarNotCrowdedMiddle;
    case "middle/some_crowding":
      return CarSomeCrowdingMiddle;
    case "middle/crowded":
      return CarCrowdedMiddle;
    case "middle/no_data":
      return CarNoDataMiddle;
    case "middle/closed":
      return CarClosedMiddle;
  }
};

interface FooterSegmentProps {
  children: React.ReactNode;
  identifiers: string;
  showIdentifiers: boolean;
}

// Wrapper for footer segments so there is less code duplication when adding identifiers
const FooterSegment: React.ComponentType<FooterSegmentProps> = ({
  children,
  identifiers,
  showIdentifiers,
}) => {
  return (
    <div className="crowding-widget__footer__segment">
      {children}
      {showIdentifiers && (
        <div className="crowding-widget__footer__identifiers">
          {identifiers}
        </div>
      )}
    </div>
  );
};

interface Props {
  arrivalTime: string;
  crowding: OccupancyStatus[];
  destination: string;
  front_car_direction: FrontCarDirection;
  now: string;
  platform_position: number;
  show_identifiers: boolean;
}

const TrainCrowding: React.ComponentType<Props> = ({
  crowding,
  destination,
  platform_position: platformPosition,
  front_car_direction: frontCarDirection,
  now,
  show_identifiers: showIdentifiers,
}) => {
  // If the front car direction is right, the crowding array needs to be reversed
  // so the last car is rendered on the left.
  const trains = crowding.map((occupancyStatus, i) => {
    const CarComponent = lookupCarComponent(
      occupancyStatus,
      i == 0 ? frontCarDirection : "middle"
    );
    return <CarComponent key={i} className="crowding-widget__train-car" />;
  });

  const trainSequence =
    frontCarDirection == "left" ? trains : [...trains].reverse();

  // If arrow is between screens, scoot the arrow to the next slot on the right
  // If arrow is beyond the end of the train (slot 25), scoot arrow left
  let arrowSlot;
  if ([1, 9, 17].includes(platformPosition)) {
    arrowSlot = platformPosition + 1;
  } else {
    if (platformPosition == 25) {
      arrowSlot = platformPosition - 1;
    } else arrowSlot = platformPosition;
  }

  // The slot arrangement exceeds the edges of the screen, so to properly set the slot positions
  // we need to make a few adjustments.
  const screenWidth = 3240;
  const slotOverhang = 35;
  const slotsWidth = screenWidth + slotOverhang * 2;
  const extraArrowPadding = 24;
  const arrowLeftPadding =
    (arrowSlot - 1) * (slotsWidth / 25) - slotOverhang - extraArrowPadding;
  const arrowDirection = [1, 9, 17].includes(platformPosition)
    ? "up-left"
    : platformPosition == 25
    ? "up-right"
    : "up";

  const textPane = Math.floor((arrowSlot / 25) * 3);
  const textPadding = (textPane * 3240) / 3;

  const playerName = usePlayerName();
  let identifiers = `${TRIPTYCH_VERSION} ${playerName ? playerName : ""}`;

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
                arrowDirection
              )}
            />
          ) : (
            <ArrowUpLeft
              className={classWithModifier(
                "crowding-widget__you-are-here-arrow",
                arrowDirection
              )}
            />
          )}
        </div>
        <div
          style={{ marginLeft: textPadding }}
          className={classWithModifier(
            "crowding-widget__you-are-here-text",
            [8, 16, 24].includes(arrowSlot) ? "right-align" : "left-align"
          )}
        >
          You are here
        </div>
      </div>
      <div className="crowding-widget__footer">
        <FooterSegment
          showIdentifiers={showIdentifiers}
          identifiers={identifiers}
        >
          Space available
          <br /> on board
        </FooterSegment>
        <FooterSegment
          showIdentifiers={showIdentifiers}
          identifiers={identifiers}
        >
          <div className="crowding-widget__footer__key-row">
            <KeyNotCrowded width="137" height="100" className="key-icon" />
            Seats available
          </div>
          <div className="crowding-widget__footer__key-row">
            <KeySomeCrowding width="137" height="100" className="key-icon" />
            Space available
          </div>
        </FooterSegment>
        <FooterSegment
          showIdentifiers={showIdentifiers}
          identifiers={identifiers}
        >
          <div className="crowding-widget__footer__key-row">
            <KeyCrowded width="137" height="100" className="key-icon" /> Limited
            space
          </div>
          <div className="crowding-widget__footer__key-row">
            {crowding.includes("closed") ? (
              <>
                <KeyClosed width="137" height="100" className="key-icon" /> Car
                closed
              </>
            ) : (
              crowding.includes("no_data") && (
                <>
                  <KeyNoData width="137" height="100" className="key-icon" /> No
                  data
                </>
              )
            )}
          </div>
        </FooterSegment>
      </div>
    </div>
  );
};

export default TrainCrowding;
