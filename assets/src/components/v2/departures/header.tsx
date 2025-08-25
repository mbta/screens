import cx from "classnames";
import Arrow45 from "Images/Arrow-45-no-padding.svg";

type CardinalDirection = "n" | "ne" | "e" | "se" | "s" | "sw" | "w" | "nw";

type Header = {
  title: string | null;
  arrow: CardinalDirection | null;
  subtitle: string | null;
};

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

const Header = ({ title, arrow, subtitle }: Header) => {
  return (
    <>
      <header className="departures-header">
        {(title || arrow) && <span>{title}</span>}
        {arrow && <DirectionArrow arrow={arrow} />}
      </header>
      {subtitle && (
        <div className="departures-header__subtitle">
          {formatSubtitle(subtitle)}
        </div>
      )}
    </>
  );
};

const formatSubtitle = (subtitle: string): JSX.Element[] | null => {
  return subtitle
    ? subtitle.split(/(\*\*[^*]+\*\*)/g).map((part, i) => {
        if (/^\*\*[^*]+\*\*$/.test(part)) {
          return <strong key={i}>{part.slice(2, -2)}</strong>;
        }
        return <span key={i}>{part}</span>;
      })
    : null;
};

export default Header;
