import React from "react";
import cx from "classnames";
import Arrow45 from "Images/svgr_bundled/Arrow-45-no-padding.svg";

type CardinalDirection = "n" | "ne" | "e" | "se" | "s" | "sw" | "w" | "nw";

interface Props {
  title: string | null;
  arrow: CardinalDirection | null;
}

const DirectionArrow = ({ arrow }: { arrow: CardinalDirection }) => (
  <Arrow45
    className={cx("direction-arrow", {
      "rotate-45": arrow === "n",
      "rotate-90": arrow === "ne",
      "rotate-135": arrow === "e",
      "rotate-180": arrow === "se",
      "rotate-225": arrow === "s",
      "rotate-270": arrow === "sw",
      "rotate-315": arrow === "w",
    })}
  />
);

const Header = ({ title, arrow }: Props) => {
  return (
    <header className="departures-header">
      {(title || arrow) && <span>{title}</span>}
      {arrow && <DirectionArrow arrow={arrow} />}
    </header>
  );
};

export default Header;
