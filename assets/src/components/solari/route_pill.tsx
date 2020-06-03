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

const Pill = ({ routeName, routePillColor }: PillType): JSX.Element => (
  <div className={classWithModifier("departure-route", routePillColor)}>
    {routeName && <BaseRoutePill route={routeName} />}
  </div>
);

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

const PagedDepartureRoutePill = ({ route, routeId, selected }): JSX.Element => {
  const selectedModifier = selected ? "selected" : "unselected";
  const slashModifier = route.includes("/") ? "with-slash" : "no-slash";
  const modeModifier = routeId.startsWith("CR-") ? "commuter-rail" : "bus";
  const modifiers = [selectedModifier, slashModifier, modeModifier];
  const pillClass = classWithModifiers(
    "later-departure__route-pill",
    modifiers
  );
  const textClass = classWithModifiers(
    "later-departure__route-text",
    modifiers
  );

  return (
    <div className={pillClass}>
      <div className={textClass}>{route}</div>
    </div>
  );
};

export { DepartureRoutePill, SectionRoutePill, PagedDepartureRoutePill };
