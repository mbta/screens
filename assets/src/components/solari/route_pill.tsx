import React from "react";

import { classWithModifier, classWithModifiers } from "Util/util";
import BaseRoutePill from "Components/eink/base_route_pill";

interface PillType {
  routeName: string | null;
  routePillColor: string | null;
}

const routeToPill = (route: string, routeId: string): PillType => {
  if (route === null) {
    return { routeName: null, routePillColor: null };
  }

  if (routeId === "Blue") {
    return { routeName: "BL", routePillColor: "blue" };
  }

  if (routeId === "Red") {
    return { routeName: "RL", routePillColor: "red" };
  }

  if (routeId === "Mattapan") {
    return { routeName: "M", routePillColor: "red" };
  }

  if (routeId === "Orange") {
    return { routeName: "OL", routePillColor: "orange" };
  }

  if (routeId.startsWith("CR")) {
    return { routeName: "CR", routePillColor: "purple" };
  }

  if (route.startsWith("SL")) {
    return { routeName: route, routePillColor: "silver" };
  }

  return { routeName: route, routePillColor: "yellow" };
};

const Pill = ({ routeName, routePillColor }: PillType): JSX.Element => {
  if (routeName === "CR") {
    routeName = (
      <img
        className="departure-route--icon"
        src="/images/commuter-rail.svg"
      ></img>
    );
  } else if (routeName === "BUS") {
    routeName = (
      <img className="departure-route--icon" src="/images/bus-black.svg"></img>
    );
  }

  return (
    <div className={classWithModifier("departure-route", routePillColor)}>
      {routeName && <BaseRoutePill route={routeName} />}
    </div>
  );
};

const DepartureRoutePill = ({
  route,
  routeId,
}: {
  route: string;
  routeId: string;
}): JSX.Element => <Pill {...routeToPill(route, routeId)} />;

const sectionPillMapping: Record<string, PillType> = {
  blue: { routeName: "BL", routePillColor: "blue" },
  red: { routeName: "RL", routePillColor: "red" },
  mattapan: { routeName: "M", routePillColor: "red" },
  orange: { routeName: "OL", routePillColor: "orange" },
  cr: { routeName: "CR", routePillColor: "purple" },
  silver: { routeName: "SL", routePillColor: "silver" },
  bus: { routeName: "BUS", routePillColor: "yellow" },
};

const sectionPillToPill = (pill: string): PillType => {
  return sectionPillMapping[pill] ?? { routeName: null, routePillColor: null };
};

const SectionRoutePill = ({ pill }: { pill: string }): JSX.Element => (
  <Pill {...sectionPillToPill(pill)} />
);

// Three-letter abbreviations for commuter rail routes
const routeIdMapping: Record<string, string> = {
  "CR-Haverhill": "HVL",
  "CR-Newburyport": "NBP",
  "CR-Lowell": "LWL",
  "CR-Fitchburg": "FBG",
  "CR-Worcester": "WOR",
  "CR-Needham": "NDM",
  "CR-Franklin": "FRK",
  "CR-Providence": "PVD",
  "CR-Fairmount": "FMT",
  "CR-Middleborough": "MID",
  "CR-Kingston": "KNG",
  "CR-Greenbush": "GRB",
};

const PagedDepartureRoutePill = ({
  route,
  routeId,
  selected,
  index,
}): JSX.Element => {
  const isCommuterRail = routeId.startsWith("CR-");
  const isSlashRoute = route.includes("/");

  const selectedModifier = selected ? "selected" : "unselected";
  const sizeModifier =
    isCommuterRail || isSlashRoute ? "size-small" : "size-normal";
  const modeModifier = isCommuterRail ? "commuter-rail" : "bus";
  const indexModifier = `index${index}`;
  const modifiers = [
    selectedModifier,
    sizeModifier,
    modeModifier,
    indexModifier,
  ];
  const pillClass = classWithModifiers(
    "later-departure__route-pill",
    modifiers
  );
  const textClass = classWithModifiers(
    "later-departure__route-text",
    modifiers
  );

  const routeText = routeId.startsWith("CR-") ? routeIdMapping[routeId] : route;

  return (
    <div className={pillClass}>
      <div className={textClass}>{routeText}</div>
    </div>
  );
};

export { DepartureRoutePill, SectionRoutePill, PagedDepartureRoutePill };
