import React from "react";
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

enum ScreenType {
  ELEVATOR = "elevator",
}

interface ArrowDescriptor {
  imageName: string;
  className: string;
}

/**
 * Returns an ArrowDescriptor containing an arrow SVG and CSS class that determines arrow rotation
 * Can return different arrows for different screen types, but only does this for elevator screens now.
 */
const directionToArrow = (
  direction: Direction,
  screen_type?: ScreenType,
): ArrowDescriptor => {
  let imageName: string;
  switch (direction) {
    case Direction.N:
    case Direction.E:
    case Direction.S:
    case Direction.W:
      imageName =
        screen_type === ScreenType.ELEVATOR
          ? "arrow-elevator.svg"
          : "arrow.svg";
      break;
    case Direction.UTURN:
      imageName = "turn-around-arrow.svg";
      break;
    default:
      imageName =
        screen_type === ScreenType.ELEVATOR
          ? "arrow-elevator-45.svg"
          : "arrow-45.svg";
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
  screenType,
}: {
  direction: Direction;
  className: string;
  screenType?: ScreenType;
}): JSX.Element => {
  const { imageName, className: baseClassName } = directionToArrow(
    direction,
    screenType,
  );
  return (
    <img
      className={`${baseClassName} ${className}`}
      src={imagePath(imageName)}
    />
  );
};

export default Arrow;
export { Direction, ScreenType };
