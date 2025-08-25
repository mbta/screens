import { imagePath } from "Util/utils";

/*
- arrow.svg points North
- arrow-45.svg points Northwest
*/

enum Direction {
  N = "n",
  NE = "ne",
  E = "e",
  SE = "se",
  S = "s",
  SW = "sw",
  W = "w",
  NW = "nw",
  UTURN = "uturn",
}

enum LineWeight {
  THICK = "thick",
  THIN = "thin",
}

interface ArrowDescriptor {
  imageName: string;
  className: string;
}

/**
 * Returns an ArrowDescriptor containing an arrow SVG and CSS class that determines arrow rotation
 * Defaults to a thickset arrow if no arrow type is specified
 */
const directionToArrow = (
  direction: Direction,
  lineWeight: LineWeight = LineWeight.THICK,
): ArrowDescriptor => {
  let imageName: string;
  switch (direction) {
    case Direction.N:
    case Direction.E:
    case Direction.S:
    case Direction.W:
      imageName =
        lineWeight === LineWeight.THIN ? "arrow-thin.svg" : "arrow.svg";
      break;
    case Direction.UTURN:
      imageName = "turn-around-arrow.svg";
      break;
    default:
      imageName =
        lineWeight === LineWeight.THIN ? "arrow-thin-45.svg" : "arrow-45.svg";
  }

  let className: string = "arrow__icon-image";
  switch (direction) {
    case Direction.E:
    case Direction.NE:
      className += "--rotate-90";
      break;
    case Direction.S:
    case Direction.SE:
      className += "--rotate-180";
      break;
    case Direction.W:
    case Direction.SW:
      className += "--rotate-270";
      break;
    default:
      className += "--rotate-0";
  }

  return { imageName, className };
};

const Arrow = ({
  direction,
  className,
  lineWeight,
}: {
  direction: Direction;
  className: string;
  lineWeight?: LineWeight;
}): JSX.Element => {
  const { imageName, className: baseClassName } = directionToArrow(
    direction,
    lineWeight,
  );
  return (
    <img
      className={`${baseClassName} ${className}`}
      src={imagePath(imageName)}
    />
  );
};

export default Arrow;
export { Direction, LineWeight };
