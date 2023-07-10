import { classWithModifier } from "Util/util";
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
  isCurrentStop: boolean;
}

const FirstSlotComponent: ComponentType<EndSlotComponentProps> = ({
  slot,
  line,
}) => {
  if (slot.type === "arrow") {
    return (
      <path
        className={classWithModifier("end-slot__arrow", line)}
        transform="translate(0 12)"
        d="M35 0V24L19.554 24C19.1915 24 18.8358 23.9015 18.525 23.715L1.85831 13.715C0.563633 12.9382 0.563633 11.0618 1.85831 10.285L18.525 0.285015C18.8358 0.0985165 19.1915 0 19.554 0L35 0Z"
        fill={line}
      />
    );
  } else {
    return (
      <circle
        className={classWithModifier("end-slot__icon", line)}
        cx={L + SLOT_WIDTH / 2}
        cy="24"
        r="20"
        fill="white"
        strokeWidth="8"
      />
    );
  }
};

const LastSlotComponent: ComponentType<
  EndSlotComponentProps & { x: number }
> = ({ slot, line, x, isCurrentStop }) => {
  if (slot.type === "arrow") {
    return (
      <path
        transform={`translate(${x} 12)`}
        width={204}
        d="M0 24V0H59.446C59.8085 0 60.1642 0.0985159 60.475 0.285014L77.1417 10.285C78.4364 11.0618 78.4364 12.9382 77.1417 13.715L60.475 23.715C60.1642 23.9015 59.8085 24 59.446 24H0Z"
        className={classWithModifier("end-slot__arrow", line)}
      />
    );
  } else if (isCurrentStop) {
    return (
      <path
        transform={`translate(${x - SLOT_WIDTH} -8)`}
        d="M3.13388 28.7629C1.74155 30.1552 1.74155 32.4126 3.13388 33.8049L28.2253 58.8964C29.6176 60.2887 31.8751 60.2887 33.2674 58.8964L58.3588 33.8049C59.7511 32.4126 59.7511 30.1552 58.3588 28.7629L33.2674 3.67141C31.8751 2.27909 29.6176 2.27909 28.2253 3.67141L3.13388 28.7629Z"
        fill="#EE2E24"
        stroke="#E6E4E1"
        strokeWidth="3.58209"
      />
    );
  } else {
    return (
      <circle
        cx={x}
        cy="24"
        r="20"
        fill="white"
        className={classWithModifier("end-slot__icon", line)}
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
  isCurrentStop: boolean;
  isAffected: boolean;
  effect: "shuttle" | "suspension" | "station_closure";
}

const MiddleSlotComponent: ComponentType<MiddleSlotComponentProps> = ({
  slot,
  x,
  spaceBetween,
  line,
  isCurrentStop,
  isAffected,
  effect,
}) => {
  let background;
  if (isAffected) {
    switch (effect) {
      case "shuttle":
        background = <></>;
        break;
      case "suspension":
        background = (
          <rect
            width={SLOT_WIDTH + spaceBetween}
            height="16"
            x={x}
            y="16"
            fill="#AEAEAE"
          />
        );
        break;
      case "station_closure":
        background = (
          <rect
            className={classWithModifier("middle-slot__background", line)}
            width={SLOT_WIDTH + spaceBetween}
            height={LINE_HEIGHT}
            x={x}
            y="12"
          />
        );
    }
  } else {
    background = (
      <rect
        className={classWithModifier("middle-slot__background", line)}
        width={SLOT_WIDTH + spaceBetween}
        height={LINE_HEIGHT}
        x={x}
        y="12"
      />
    );
  }

  let icon;
  if (slot.show_symbol) {
    if (isCurrentStop) {
      icon = (
        <>
          <path
            transform={`translate(${x - SLOT_WIDTH} -4)`}
            d="M32.6512 3.92661C30.0824 1.3578 25.9176 1.3578 23.3488 3.92661L3.92661 23.3488C1.3578 25.9176 1.3578 30.0824 3.92661 32.6512L23.3488 52.0734C25.9176 54.6422 30.0824 54.6422 32.6512 52.0734L52.0734 32.6512C54.6422 30.0824 54.6422 25.9176 52.0734 23.3488L32.6512 3.92661Z"
            className={classWithModifier("middle-slot__background", line)}
            stroke="#E6E4E1"
            strokeWidth="4"
            strokeLinejoin="round"
          />
          <path
            transform={`translate(${x - SLOT_WIDTH} -4)`}
            fillRule="evenodd"
            clipRule="evenodd"
            d="M15.4855 29.219C14.7045 28.438 14.7045 27.1717 15.4855 26.3906L26.3906 15.4855C27.1717 14.7045 28.438 14.7045 29.219 15.4855L40.1242 26.3906C40.9052 27.1717 40.9052 28.438 40.1241 29.219L29.219 40.1242C28.438 40.9052 27.1717 40.9052 26.3906 40.1241L15.4855 29.219Z"
            fill="white"
          />
        </>
      );
    } else {
      if (isAffected) {
        switch (effect) {
          case "suspension":
            icon = (
              <>
                <rect x={x} y="16" width="17" height="16" fill="white" />
                <path
                  transform={`translate(${x - 8} 8)`}
                  fillRule="evenodd"
                  clipRule="evenodd"
                  d="M8.93886 0C8.76494 0 8.5985 0.0707868 8.47786 0.196069L0.178995 8.81412C0.0641567 8.93338 0 9.09249 0 9.25805V21.0682C0 21.238 0.0674284 21.4008 0.187452 21.5208L8.47922 29.8125C8.59924 29.9326 8.76202 30 8.93176 30H21.0611C21.2351 30 21.4015 29.9292 21.5221 29.8039L29.821 21.1859C29.9358 21.0666 30 20.9075 30 20.7419V8.93176C30 8.76202 29.9326 8.59924 29.8125 8.47922L21.5208 0.187452C21.4008 0.0674284 21.238 0 21.0682 0H8.93886ZM7.5935 10.0066C7.34658 10.2576 7.34866 10.6608 7.59816 10.9091L11.957 15.248L7.59623 19.6793C7.34824 19.9313 7.35156 20.3366 7.60365 20.5845L9.73397 22.6794C9.98593 22.9272 10.391 22.9239 10.6389 22.672L15 18.2404L19.3611 22.672C19.609 22.9239 20.0141 22.9272 20.266 22.6794L22.3964 20.5845C22.6484 20.3366 22.6518 19.9313 22.4038 19.6793L18.043 15.248L22.4018 10.9091C22.6513 10.6608 22.6534 10.2576 22.4065 10.0066L20.2613 7.82685C20.0124 7.5739 19.6052 7.5718 19.3537 7.82217L15 12.1559L10.6463 7.82217C10.3948 7.5718 9.98758 7.5739 9.73865 7.82685L7.5935 10.0066Z"
                  fill="#171F26"
                />
              </>
            );
            break;

          case "station_closure":
            icon = (
              <>
                <path
                  transform={`translate(${x - SLOT_WIDTH} -2)`}
                  d="M22.6628 27.0001L23.9119 25.7308L22.6498 24.4744L17.0202 18.8706L18.8677 16.9933L24.4828 22.5826L25.7463 23.8404L27.0099 22.5826L32.625 16.9933L34.4725 18.8706L28.8429 24.4744L27.5807 25.7308L28.8298 27.0001L34.4649 32.7261L32.6588 34.5021L27.0229 28.7751L25.7463 27.4779L24.4698 28.7751L18.8338 34.5021L17.0278 32.7261L22.6628 27.0001ZM35.0884 18.2575L35.0876 18.2583L35.0884 18.2575ZM19.4568 35.1147L19.456 35.114L19.4568 35.1147ZM3.22013 15.2827L4.51025 16.5251L3.22013 15.2827C2.73421 15.7873 2.46274 16.4606 2.46274 17.1611V34.0832C2.46274 34.8014 2.74805 35.4902 3.25592 35.9981L15.1366 47.8788L16.4031 46.6124L15.1367 47.8788C15.6445 48.3867 16.3333 48.672 17.0515 48.672H34.4309C35.1669 48.672 35.8711 48.3725 36.3816 47.8424L48.2725 35.4941C48.7585 34.9895 49.0299 34.3162 49.0299 33.6157V16.6936C49.0299 15.9754 48.7446 15.2866 48.2368 14.7788L46.9703 16.0452L48.2367 14.7787L36.356 2.898C35.8481 2.39014 35.1593 2.10483 34.4411 2.10483H17.0617C16.3258 2.10483 15.6215 2.40435 15.111 2.93447L3.22013 15.2827Z"
                  fill="#171F26"
                  stroke="#E6E4E1"
                  strokeWidth="3.58209"
                />
              </>
            );
            break;
          case "shuttle":
            icon = <></>;
        }
      } else {
        icon = (
          <circle
            cx={x}
            cy="24"
            r="10"
            fill="white"
            className={classWithModifier("middle-slot__icon", line)}
            strokeWidth="4"
          />
        );
      }
    }
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

const DisruptionDiagram: ComponentType<DisruptionDiagramData> = (props) => {
  const { slots, current_station_slot_index, line, effect } = props;
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
    const isAffected =
      effect === "station_closure"
        ? props.closed_station_slot_indices.includes(i + 1)
        : i >= props.effect_region_slot_index_range[0] - 2 &&
          i <= props.effect_region_slot_index_range[1] - 1;
    return (
      <MiddleSlotComponent
        key={key}
        slot={slot}
        x={x}
        spaceBetween={spaceBetween}
        line={line}
        isCurrentStop={current_station_slot_index === i + 1}
        effect={effect}
        isAffected={isAffected}
      />
    );
  });

  x += spaceBetween + SLOT_WIDTH;

  return (
    <div style={{ width: "904px", height: "308px" }}>
      <svg
        width="904px"
        version="1.1"
        xmlns="http://www.w3.org/2000/svg"
        style={{ padding: "24px" }}
      >
        <FirstSlotComponent
          slot={beginning}
          line={line}
          isCurrentStop={current_station_slot_index === 0}
        />
        <rect
          className={classWithModifier("end-slot__arrow", line)}
          width={SLOT_WIDTH / 2 + spaceBetween}
          height={LINE_HEIGHT}
          fill={line}
          x={L + SLOT_WIDTH / 2}
          y="12"
        />
        {middleSlots}
        <LastSlotComponent
          slot={end as EndSlot}
          x={x}
          line={line}
          isCurrentStop={current_station_slot_index === slots.length - 1}
        />
      </svg>
    </div>
  );
};

export { ContinuousDisruptionDiagram };

export default DisruptionDiagram;
