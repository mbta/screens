import React, { ComponentType } from "react";

const MAX_WIDTH = 904;
const SLOT_WIDTH = 24;
const LINE_HEIGHT = 24;
const L = 13;
// TODO: Make this based on headsign
const R = 165;
const W = MAX_WIDTH - (L + R);

type DisruptionDiagramData =
  | ContinuousDisruptionDiagram
  | DiscreteDisruptionDiagram;

interface DisruptionDiagramBase {
  line: LineColor;
  current_station_slot_index: number | null;
  slots: [EndSlot, ...MiddleSlot[], EndSlot];
}

interface ContinuousDisruptionDiagram extends DisruptionDiagramBase {
  effect: "shuttle" | "suspension";
  // Range starts and ends at the effect region's *first and last disrupted stops*.
  // For example in this scenario:
  //     0     1     2     3     4     5     6     7     8
  //    <= === O ========= O - - X - - X - - X - - O === O
  //                             |---range---|
  // The range is [4, 6].
  effect_region_slot_index_range: [range_start: number, range_end: number];
}

interface DiscreteDisruptionDiagram extends DisruptionDiagramBase {
  effect: "station_closure";
  closed_station_slot_indices: number[];
}

interface EndSlot {
  type: "arrow" | "terminal";
  label_id: EndLabelID;
}

interface MiddleSlot {
  label: Label;
  show_symbol: boolean;
}

// Note the single ellipsis character, not 3 periods
type Label = "…" | { full: string; abbrev: string };

// End labels have hardcoded presentation, so we just send an ID for the client to use in
// a lookup.
//
// TBD what these IDs will look like. We might just use parent station IDs.
//
// The rest of the labels' presentations are computed based on the height of the end labels,
// so we can send actual text for those--it will be dynamically resized to fit.
type EndLabelID = string;

type LineColor = "blue" | "orange" | "red" | "green";

const stopCircle = (
  <circle
    cx="14"
    cy="14"
    r="12"
    fill="white"
    stroke="#171F26"
    strokeWidth="4"
  />
);

const terminalCircle = (
  <circle
    cx="24"
    cy="24"
    r="20"
    fill="white"
    stroke="#171F26"
    strokeWidth="8"
  />
);

const homeStopIcon = (
  <path
    d="M3.15665 25.2076C1.61445 26.7498 1.61445 29.2502 3.15665 30.7924L25.2076 52.8434C26.7498 54.3856 29.2502 54.3855 30.7924 52.8433L52.8434 30.7924C54.3856 29.2502 54.3856 26.7498 52.8434 25.2076L30.7924 3.15665C29.2502 1.61445 26.7498 1.61445 25.2076 3.15665L3.15665 25.2076Z"
    fill="#EE2E24"
    stroke="#E6E4E1"
    strokeWidth="4"
  />
);

const homeStopTerminalIcon = (
  <>
    <path
      d="M39.4605 4.26181C36.4447 1.24606 31.5553 1.24606 28.5395 4.26181L4.26181 28.5395C1.24606 31.5553 1.24606 36.4447 4.26181 39.4605L28.5395 63.7382C31.5553 66.7539 36.4447 66.7539 39.4605 63.7382L63.7382 39.4605C66.7539 36.4447 66.7539 31.5553 63.7382 28.5395L39.4605 4.26181Z"
      fill="#EE2E24"
      stroke="#E6E4E1"
      strokeWidth="4"
      strokeLinejoin="round"
    />
    <path
      fillRule="evenodd"
      clipRule="evenodd"
      d="M18.0032 35.1702C17.2222 34.3892 17.2222 33.1229 18.0032 32.3418L32.3417 18.0033C33.1228 17.2223 34.3891 17.2223 35.1702 18.0033L49.5086 32.3418C50.2897 33.1229 50.2897 34.3892 49.5086 35.1702L35.1702 49.5087C34.3891 50.2898 33.1228 50.2898 32.3417 49.5087L18.0032 35.1702Z"
      fill="white"
    />
  </>
);

interface EndSlotComponentProps {
  slot: EndSlot;
  line: LineColor;
}

const FirstSlotComponent: ComponentType<EndSlotComponentProps> = ({
  slot,
  line,
}) => {
  if (slot.type === "arrow") {
    return (
      <path
        transform="translate(0 12)"
        d="M35 0V24L19.554 24C19.1915 24 18.8358 23.9015 18.525 23.715L1.85831 13.715C0.563633 12.9382 0.563633 11.0618 1.85831 10.285L18.525 0.285015C18.8358 0.0985165 19.1915 0 19.554 0L35 0Z"
        fill={line}
      />
    );
  } else {
    return (
      <circle
        cx={L + SLOT_WIDTH / 2}
        cy="24"
        r="20"
        fill="white"
        stroke="#171F26"
        strokeWidth="8"
      />
    );
  }
};

const LastSlotComponent: ComponentType<
  EndSlotComponentProps & { x: number }
> = ({ slot, line, x }) => {
  if (slot.type === "arrow") {
    return (
      <path
        transform={`translate(${x} 12)`}
        width={204}
        d="M0 24V0H59.446C59.8085 0 60.1642 0.0985159 60.475 0.285014L77.1417 10.285C78.4364 11.0618 78.4364 12.9382 77.1417 13.715L60.475 23.715C60.1642 23.9015 59.8085 24 59.446 24H0Z"
        fill={line}
      />
    );
  } else {
    return (
      <circle
        cx={x}
        cy="24"
        r="20"
        fill="white"
        stroke="#171F26"
        strokeWidth="8"
      />
    );
  }
};

interface MiddleSlotComponentProps {
  slot: MiddleSlot;
  x: number;
  spaceBetween: number;
  line: LineColor;
}

const MiddleSlotComponent: ComponentType<MiddleSlotComponentProps> = ({
  slot,
  x,
  spaceBetween,
  line,
}) => {
  const background = (
    <rect
      width={SLOT_WIDTH + spaceBetween}
      height={LINE_HEIGHT}
      fill={line}
      x={x}
      y="12"
    />
  );

  let icon;
  if (slot.show_symbol) {
    icon = (
      <circle
        cx={x}
        cy="24"
        r="10"
        fill="white"
        stroke={line}
        strokeWidth="4"
      />
    );
  } else {
    icon = <div>…</div>;
  }

  return (
    <>
      {background}
      {icon}
    </>
  );
};

/*
Client is responsible for:
- choosing the appropriate symbol for each slot based on whether the stop is inside/outside the effect region, whether it's the current stop, whether it's a Red Line diagram, whether show_symbol is true/false
- setting the appropriate label styles based on whether it's an end, whether it's the current stop, whether it's an ellipsis
- doing some sort of mapping/lookup like {endLabelID, leftOrRight} -> endLabelPresentation
- abbreviating middle labels when they're more than 8px taller than the tallest end label
- sizing, spacing, positioning of edges/end arrows/shuttle dashes/the diagram as a whole within its container
*/

// R=165
// L=11
// W=728

const DisruptionDiagram: ComponentType<DisruptionDiagramData> = ({
  slots,
  current_station_slot_index,
  line,
}) => {
  const numStops = slots.length;
  const spaceBetween = Math.min(
    60,
    (W - SLOT_WIDTH * numStops) / (numStops - 1)
  );
  const { 0: beginning, [slots.length - 1]: end, ...middle } = slots;
  let x = 0;
  const middleSlots = Object.values(middle).map((s, i) => {
    x = (spaceBetween + SLOT_WIDTH) * (i + 1);
    const slot = s as MiddleSlot;
    const key = slot.label === "…" ? i : slot.label.full;
    console.log(x);
    return (
      <MiddleSlotComponent
        key={key}
        slot={slot}
        x={x}
        spaceBetween={spaceBetween}
        line={line}
      />
    );
  });

  x += spaceBetween + SLOT_WIDTH;

  return (
    <svg
      width="904px"
      height="308px"
      viewBox={[0, 0, 904, 308].join(" ")}
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
    >
      <FirstSlotComponent slot={beginning} line={line} />
      <rect
        width={SLOT_WIDTH / 2 + spaceBetween}
        height={LINE_HEIGHT}
        fill={line}
        x={L + SLOT_WIDTH / 2}
        y="12"
      />
      {middleSlots}
      <LastSlotComponent slot={end as EndSlot} x={x} line={line} />
    </svg>
  );
};

export { ContinuousDisruptionDiagram };

export default DisruptionDiagram;
