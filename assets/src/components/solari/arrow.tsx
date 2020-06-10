import React from "react";

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
}

interface ArrowDescriptor {
  imageName: string;
  className: string;
}

const directionToArrow = (direction: Direction): ArrowDescriptor => {
  let imageName: string;
  switch (direction) {
    case Direction.N:
    case Direction.E:
    case Direction.S:
    case Direction.W:
      imageName = "arrow.svg";
      break;
    default:
      imageName = "arrow-45.svg";
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
}: {
  direction: Direction;
  className: string;
}): JSX.Element => {
  const { imageName, className: baseClassName } = directionToArrow(direction);
  return (
    <img
      className={`${baseClassName} ${className}`}
      src={`/images/${imageName}`}
    />
  );
};

export default Arrow;
export { Direction };
