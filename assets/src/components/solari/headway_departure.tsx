import React from "react";

import BaseDepartureDestination from "Components/eink/base_departure_destination";
import { SectionRoutePill } from "Components/solari/route_pill";

import { classWithModifier, classWithModifiers } from "Util/util";

const HeadwayDeparture = ({
  pill,
  headsign,
  rangeLow,
  rangeHigh,
}): JSX.Element => {
  return (
    <div
      className={classWithModifiers("departure-container", [
        "group-start",
        "group-end",
      ])}
    >
      <div className={classWithModifier("departure", "no-via")}>
        <SectionRoutePill pill={pill} />
        <div className="departure-headway__destination">
          <BaseDepartureDestination destination={headsign} />
        </div>
        <div className="departure-headway">
          <div className="departure-headway__highlight">
            <div className="departure-headway__message">
              Every
              <span className="departure-headway__range">
                {" "}
                {rangeLow} - {rangeHigh}
              </span>
              m
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HeadwayDeparture;
