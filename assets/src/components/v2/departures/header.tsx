import React from "react";
import cx from "classnames";
import Arrow45 from "Images/svgr_bundled/Arrow-45-no-padding.svg";

type CardinalDirection = "n" | "ne" | "e" | "se" | "s" | "sw" | "w" | "nw";

interface Props {
  title: string | null;
  direction: CardinalDirection | null;
}

const DirectionArrow = ({ direction }: { direction: CardinalDirection }) => (
  <Arrow45
    className={cx("direction-arrow", {
      "rotate-45": direction === "n",
      "rotate-90": direction === "ne",
      "rotate-135": direction === "e",
      "rotate-180": direction === "se",
      "rotate-225": direction === "s",
      "rotate-270": direction === "sw",
      "rotate-315": direction === "w",
    })}
  />
);

const Header = ({ title, direction }: Props) => {
  return (
    <header className="departures-header">
      {(title || direction) && <span>{title}</span>}
      {direction && <DirectionArrow direction={direction} />}
    </header>
  );
};

export default Header;
