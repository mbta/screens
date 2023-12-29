// SPECIFICATION: https://www.notion.so/mbta-downtown-crossing/Disruption-Diagram-Specification-a779027385b545abbff6fb4b4fd0adc1

import React, { ComponentType, useEffect, useState } from "react";
import { classWithModifier, classWithModifiers } from "Util/util";

import LargeXOctagonBordered from "../../../../static/images/svgr_bundled/disruption_diagram/large-x-octagon-bordered.svg";
import SmallXOctagon from "../../../../static/images/svgr_bundled/disruption_diagram/small-x-octagon.svg";
import CurrentStopDiamond from "../../../../static/images/svgr_bundled/disruption_diagram/current-stop-diamond.svg";
import CurrentStopOpenDiamond from "../../../../static/images/svgr_bundled/disruption_diagram/current-stop-open-diamond.svg";
import ArrowLeftEndpoint from "../../../../static/images/svgr_bundled/disruption_diagram/arrow-left-endpoint.svg";
import ArrowRightEndpoint from "../../../../static/images/svgr_bundled/disruption_diagram/arrow-right-endpoint.svg";
import ShuttleBusIcon from "../../../../static/images/svgr_bundled/disruption_diagram/shuttle-emphasis-icon.svg";

// Max width of the disruption diagram, dependent on the screen width
const MAX_WIDTH = 904;
const SLOT_WIDTH = 24;
// Height of the colored line for the diagram
const LINE_HEIGHT = 24;
const EMPHASIS_HEIGHT = 80;
// This padding is only used in 1 spot, and it may not be the most accurate measure
// of the padding above the emphasis. Keeping for now
const EMPHASIS_PADDING_TOP = 8;
// The tallest icon (the diamond) is used in translation calculations
const MAX_ENDPOINT_HEIGHT = 64;
const LARGE_X_STOP_ICON_HEIGHT = 48;
// L: the amount by which the left end extends beyond the leftmost station slot.
// R: the width by which the right end extends beyond the rightmost station slot.
// L can vary based on whether the first slot is an arrow vs diamond, because the diamond is larger.
// Would be nice if this was programmatic, but this works for now
const L = MAX_ENDPOINT_HEIGHT / 2;
const R = 165;
// The width taken up by the ends outside the typical station bounds is L + R,
// so the width available to the rest of the diagram is 904 - (L + R)
const W = MAX_WIDTH - (L + R);

type DisruptionDiagramData =
  | ContinuousDisruptionDiagram
  | DiscreteDisruptionDiagram;

interface DisruptionDiagramBase {
  line: LineColor;
  current_station_slot_index: number;
  slots: [EndSlot, ...MiddleSlot[], EndSlot];
  svgHeight: number;
}

interface ContinuousDisruptionDiagram extends DisruptionDiagramBase {
  effect: "shuttle" | "suspension";
  // Range starts and ends at the effect region's *boundary stops*, inclusive.
  // For example in this scenario:
  //     0     1     2     3     4     5     6     7     8
  //    <= === O ========= O - - X - - X - - X - - O === O
  //                       |---------range---------|
  // The range is [3, 7].
  //
  // SPECIAL CASE:
  // If the range starts at 0 or ends at the last element of the array,
  // then the symbol for that terminal stop should use the appropriate
  // disruption symbol, not the "normal service" symbol.
  // For example if the range is [0, 5], the left end of the
  // diagram should use a disruption symbol:
  //     0     1     2     3     4     5     6     7     8
  //     X - - X - - X - - X - - X - - O ========= O === =>
  //     |------------range------------|
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

type LineColor = "blue" | "orange" | "red" | "green";

type Effect = "shuttle" | "suspension" | "station_closure";

// End labels have hardcoded presentation, so we just send an ID for the client to use in
// a lookup.
//
// The rest of the labels' presentations are computed based on the height of the end labels,
// so we can send actual text for those--it will be dynamically resized to fit.
type EndLabelID = string;

// If value is length === 2, label is split onto 2 lines.
const endLabelIDMap: { [labelID: string]: string[] } = {
  "place-bomnl": ["BOWDOIN"],
  "place-wondl": ["WONDERLAND"],
  "place-alfcl": ["ALEWIFE"],
  "place-asmnl+place-brntn": ["ASHMONT &", "BRAINTREE"],
  "place-asmnl": ["ASHMONT"],
  "place-brntn": ["BRAINTREE"],
  "place-ogmnl": ["OAK GROVE"],
  "place-forhl": ["FOREST", "HILLS"],
  "place-gover": ["GOVERNMENT", "CENTER"],
  "place-lake": ["BOSTON COLLEGE"],
  "place-clmnl": ["CLEVELAND CIR"],
  "place-unsqu": ["UNION SQUARE"],
  "place-river": ["RIVERSIDE"],
  "place-mdftf": ["MEDFORD/TUFTS"],
  "place-hsmnl": ["HEATH ST"],
  "place-kencl": ["KENMORE"],
  "place-kencl+west": ["KENMORE & WEST"],
  "place-mdftf+place-unsqu": ["MEDFORD/TUFTS", "& UNION SQ"],
  "place-north+place-pktrm": ["NORTH STATION", "& PARK ST"],
  "place-coecl+west": ["COPLEY & WEST"],
  western_branches: ["WESTERN BRANCHES"],
};

interface IconProps {
  iconSize: number;
}

interface EndpointProps {
  className: string;
}

// Non-circle icons are translated by their top-left corner, while circles
// are translated by their center-point. So to position these non-circles,
// translate is x shifted by half the width of the icon, and y is shifted up half its
// iconsize and half the thickness of the line diagram itself
const translateNonCircleIcon = (iconSize: number) =>
  `translate(-${iconSize / 2} -${(iconSize - LINE_HEIGHT) / 2})`;

// Special current stop icon for the red line: hollow red diamond
const CurrentStopOpenDiamondIcon: ComponentType<IconProps> = ({ iconSize }) => {
  return (
    <g className="open-diamond" transform={translateNonCircleIcon(iconSize)}>
      <CurrentStopOpenDiamond width={iconSize} height={iconSize} />
    </g>
  );
};

// Current stop icon for all other lines: solid red diamond
const CurrentStopDiamondIcon: ComponentType<IconProps> = ({ iconSize }) => {
  return (
    <g className="solid-diamond" transform={translateNonCircleIcon(iconSize)}>
      <CurrentStopDiamond width={iconSize} height={iconSize} />
    </g>
  );
};

// This is the x-octagon without a border
const SmallXStopIcon: ComponentType<IconProps> = ({ iconSize }) => {
  return (
    <g className="small-x-stop" transform={translateNonCircleIcon(iconSize)}>
      <SmallXOctagon width={iconSize} height={iconSize} />
    </g>
  );
};

// This is the x-octagon with a border
const LargeXStopIcon: ComponentType<{ iconSize: number; color?: string }> = ({
  iconSize,
  color,
}) => {
  return (
    <g className="large-x-stop" transform={translateNonCircleIcon(iconSize)}>
      <LargeXOctagonBordered color={color} width={iconSize} height={iconSize} />
    </g>
  );
};

// Basic template for a Circle Icon
const CircleStopIcon: ComponentType<{
  r: number;
  className: string;
  strokeWidth: number;
}> = ({ r, className, strokeWidth }) => (
  <circle
    cy={LINE_HEIGHT / 2}
    r={r}
    fill="white"
    className={className}
    strokeWidth={strokeWidth}
  />
);

const CircleShuttlingStopIcon: ComponentType<{}> = () => (
  <CircleStopIcon r={10} className="shuttle-stop" strokeWidth={4} />
);

const CircleStopIconEndpoint: ComponentType<EndpointProps> = ({
  className,
}) => <CircleStopIcon r={20} className={className} strokeWidth={8} />;

const LeftArrowEndpoint: ComponentType<EndpointProps> = ({ className }) => (
  <ArrowLeftEndpoint className={className} />
);

const RightArrowEndpoint: ComponentType<EndpointProps> = ({ className }) => (
  <ArrowRightEndpoint className={className} />
);

const EndpointLabel: ComponentType<{ labelID: string; isArrow: boolean }> = ({
  labelID,
  isArrow,
}) => {
  let labelParts = endLabelIDMap[labelID];
  if (labelParts.length === 1) {
    return (
      <text
        className="label--endpoint"
        transform={`translate(0 -32) rotate(-45)`}
      >
        {isArrow && <tspan className="label">to </tspan>}
        {labelParts[0]}
      </text>
    );
  } else {
    return (
      <>
        <text
          className="label--endpoint"
          transform={`translate(0 -32) rotate(-45)`}
        >
          {isArrow && <tspan className="label">to </tspan>}
          {labelParts[0].includes("&") ? (
            <>
              {labelParts[0].replace(" &", "")}
              <tspan className="label"> &</tspan>
            </>
          ) : (
            labelParts[0]
          )}
        </text>
        <text
          className="label--endpoint"
          transform={`translate(45 -32) rotate(-45)`}
        >
          {labelParts[1].includes("&") ? (
            <>
              <tspan className="label">& </tspan>
              {labelParts[1].replace("& ", "")}
            </>
          ) : (
            labelParts[1]
          )}
        </text>
      </>
    );
  }
};

interface EndSlotComponentProps {
  slot: EndSlot;
  line: LineColor;
  isCurrentStop: boolean;
  isAffected: boolean;
  effect: Effect;
  spaceBetween: number;
  isLeftSide: boolean;
  x: number;
}

const EndSlotComponent: ComponentType<EndSlotComponentProps> = ({
  slot,
  line,
  isCurrentStop,
  isAffected,
  effect,
  spaceBetween,
  isLeftSide,
  x,
}) => {
  let icon;
  if (slot.type === "arrow") {
    icon = isLeftSide ? (
      <g transform={`translate(-22 0)`}>
        <LeftArrowEndpoint
          className={classWithModifier("end-slot__arrow", line)}
        />
      </g>
    ) : (
      <RightArrowEndpoint
        className={classWithModifier("end-slot__arrow", line)}
      />
    );
  } else if (isAffected && isCurrentStop) {
    icon = <LargeXStopIcon iconSize={61} color="#ee2e24" />;
  } else if (isAffected) {
    icon = <LargeXStopIcon iconSize={61} />;
  } else if (isCurrentStop && line === "red") {
    icon = <CurrentStopOpenDiamondIcon iconSize={MAX_ENDPOINT_HEIGHT} />;
  } else if (isCurrentStop) {
    icon = <CurrentStopDiamondIcon iconSize={MAX_ENDPOINT_HEIGHT} />;
  } else {
    const modifiers = [line.toString()];
    if (isAffected) {
      modifiers.push("affected");
    }
    icon = (
      <CircleStopIconEndpoint
        className={classWithModifiers("end-slot__icon", modifiers)}
      />
    );
  }

  let background;
  if (
    (!isAffected && isLeftSide) ||
    (effect === "station_closure" && isLeftSide)
  ) {
    background = (
      <rect
        className={classWithModifier("end-slot__arrow", line)}
        width={SLOT_WIDTH / 2 + spaceBetween}
        height={LINE_HEIGHT}
        fill={line}
        x={SLOT_WIDTH / 2}
      />
    );
  } else {
    background = <></>;
  }

  return (
    <g transform={`translate(${x})`}>
      {background}
      {icon}
      <EndpointLabel labelID={slot.label_id} isArrow={slot.type === "arrow"} />
    </g>
  );
};

interface MiddleSlotComponentProps {
  slot: MiddleSlot;
  x: number;
  spaceBetween: number;
  line: LineColor;
  isCurrentStop: boolean;
  isAffected: boolean;
  effect: Effect;
  firstAffectedIndex: boolean;
  abbreviate: boolean;
  labelTextClass: string;
}

const MiddleSlotComponent: ComponentType<MiddleSlotComponentProps> = ({
  slot,
  x,
  spaceBetween,
  line,
  isCurrentStop,
  isAffected,
  effect,
  firstAffectedIndex,
  abbreviate,
  labelTextClass,
}) => {
  const { label } = slot;
  let background;
  // Background for suspension/shuttle is drawn in EffectBackgroundComponent.
  if (isAffected && effect !== "station_closure") {
    background = <></>;
  } else {
    background = (
      <rect
        className={classWithModifier("middle-slot__background", line)}
        // Round up to avoid gaps due to rounded down size during render
        width={SLOT_WIDTH + Math.ceil(spaceBetween)}
        height={LINE_HEIGHT}
      />
    );
  }

  let icon;
  if (slot.show_symbol) {
    if (isCurrentStop) {
      if (isAffected) {
        icon = <LargeXStopIcon iconSize={LARGE_X_STOP_ICON_HEIGHT} color="#ee2e24" />;
      } else {
        icon =
          line === "red" ? (
            <CurrentStopOpenDiamondIcon iconSize={52} />
          ) : (
            <CurrentStopDiamondIcon iconSize={52} />
          );
      }
    } else {
      if (isAffected && !firstAffectedIndex) {
        switch (effect) {
          case "suspension":
            icon = <SmallXStopIcon iconSize={24} />;
            break;
          case "station_closure":
            icon = <LargeXStopIcon iconSize={LARGE_X_STOP_ICON_HEIGHT} />;
            break;
          case "shuttle":
            if (label !== "…" && label.full === "Beaconsfield") {
              icon = <SmallXStopIcon iconSize={24} />;
            } else {
              icon = <CircleShuttlingStopIcon />;
            }
        }
      } else {
        icon = (
          <CircleStopIcon
            r={10}
            className={classWithModifier("middle-slot__icon", line)}
            strokeWidth={4}
          />
        );
      }
    }
  } else {
    icon = <></>;
  }

  let textModifier;

  if (isCurrentStop) {
    textModifier = "current-stop";
  }

  return (
    <g transform={`translate(${x})`}>
      {background}
      {icon}
      {label === "…" ? (
        <text
          className={classWithModifier(`label-${labelTextClass}`, textModifier)}
          transform={`translate(-12 -32)`}
        >
          {" "}
          {label}{" "}
        </text>
      ) : (
        <text
          className={classWithModifier(`label-${labelTextClass}`, textModifier)}
          transform={`translate(0 -32) rotate(-45)`}
        >
          {abbreviate || label.full === "Massachusetts Avenue"
            ? label.abbrev
            : label.full}
        </text>
      )}
    </g>
  );
};

interface EffectBackgroundComponentProps {
  effectRegionSlotIndexRange:
    | [range_start: number, range_end: number]
    | number[];
  effect: Effect;
  spaceBetween: number;
}

// Only for shuttles or suspensions
const EffectBackgroundComponent: ComponentType<
  EffectBackgroundComponentProps
> = ({ spaceBetween, effect, effectRegionSlotIndexRange }) => {
  const rangeStart = effectRegionSlotIndexRange[0];
  const rangeEnd = effectRegionSlotIndexRange[1];

  const x1 = rangeStart * (spaceBetween + SLOT_WIDTH);
  const x2 = (spaceBetween + SLOT_WIDTH) * rangeEnd;
  const heightOfBackground = 16;

  let background;
  if (effect === "shuttle") {
    const dashXunit = (spaceBetween + SLOT_WIDTH) / 18;
    const dash = dashXunit * 4;
    const gap = dashXunit * 2;
    background = (
      <line
        x1={x1 + dashXunit}
        y1="12"
        x2={x2}
        y2="12"
        strokeWidth={heightOfBackground}
        stroke="black"
        strokeDasharray={`${dash} ${gap}`}
      />
    );
  } else {
    background = (
      <rect
        width={x2 - x1 + SLOT_WIDTH}
        height={heightOfBackground}
        x={x1}
        y={heightOfBackground / 4}
        fill="#AEAEAE"
      />
    );
  }

  return <>{background}</>;
};

interface AlertEmphasisComponentProps {
  effectRegionSlotIndexRange:
    | [range_start: number, range_end: number]
    | number[];
  spaceBetween: number;
  effect: "suspension" | "shuttle";
  scaleFactor: number;
}

const AlertEmphasisComponent: ComponentType<AlertEmphasisComponentProps> = ({
  effectRegionSlotIndexRange,
  spaceBetween,
  effect,
  scaleFactor,
}) => {
  const rangeStart = effectRegionSlotIndexRange[0];
  const rangeEnd = effectRegionSlotIndexRange[1];

  const x1 = rangeStart * (spaceBetween + SLOT_WIDTH) * scaleFactor;
  const x2 = (spaceBetween + SLOT_WIDTH) * rangeEnd * scaleFactor;

  const middleOfLine = (x2 - x1) / 2 + x1;
  const endLinesHeight = 24;
  const endLinesStrokeWidth = 8;

  let icon;
  if (effect === "shuttle") {
    icon = (
      <g
        transform={`translate(${middleOfLine - EMPHASIS_HEIGHT / 2} -${
          endLinesHeight + endLinesStrokeWidth / 2
        })`}
      >
        <ShuttleBusIcon />
      </g>
    );
  } else if (effect === "suspension") {
    icon = (
      <g
        transform={`translate(${middleOfLine - EMPHASIS_HEIGHT / 2} ${
          (endLinesHeight - EMPHASIS_HEIGHT) / 2
        })`}
      >
        <SmallXOctagon width={EMPHASIS_HEIGHT} height={EMPHASIS_HEIGHT} />
      </g>
    );
  }

  return (
    <>
      {effectRegionSlotIndexRange[1] - effectRegionSlotIndexRange[0] + 1 >
        2 && (
        <>
          <path
            d={`M${x1} 0L${x1} ${endLinesHeight}`}
            stroke="#737373"
            strokeWidth={`${endLinesStrokeWidth}`}
            strokeLinecap="round"
          />
          <path
            d={`M${x1} ${endLinesHeight / 2}H${x2}`}
            stroke="#737373"
            strokeWidth={`${endLinesStrokeWidth}`}
            strokeLinecap="round"
          />
          <path
            d={`M${x2} 0L${x2} ${endLinesHeight}`}
            stroke="#737373"
            strokeWidth={`${endLinesStrokeWidth}`}
            strokeLinecap="round"
          />
        </>
      )}
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

const DisruptionDiagram: ComponentType<DisruptionDiagramData> = (props) => {
  const { slots, current_station_slot_index, line, effect, svgHeight } = props;

  const [doAbbreviate, setDoAbbreviate] = useState(false);
  const [scaleFactor, setScaleFactor] = useState(1);
  const numStops = slots.length;
  const spaceBetween = Math.min(
    60,
    (W - SLOT_WIDTH * numStops) / (numStops - 1)
  );
  const [beginning, middle, end] = [slots[0], slots.slice(1, -1), slots.at(-1)];
  const hasEmphasis = effect !== "station_closure";

  const getEmphasisHeight = (scale: number) => (
    hasEmphasis
    ? EMPHASIS_HEIGHT + EMPHASIS_PADDING_TOP * scale
    : 0
  )

  const labelTextClass = slots.length > 12 ? "small" : "large";

  let x = 0;
  const middleSlots = middle.map((s, i) => {
    // Add 1 to the index to counteract the offset caused by removing `beginning` from the original `slots` array.
    const slotIndex = i + 1;
    x = (spaceBetween + SLOT_WIDTH) * slotIndex;
    const slot = s as MiddleSlot;
    const key = slot.label === "…" ? i : slot.label.full;
    const isAffected =
      effect === "station_closure"
        ? props.closed_station_slot_indices.includes(slotIndex)
        : slotIndex >= props.effect_region_slot_index_range[0] &&
          slotIndex <= props.effect_region_slot_index_range[1] - 1;

    return (
      <MiddleSlotComponent
        key={key}
        slot={slot}
        x={x}
        spaceBetween={spaceBetween}
        line={line}
        isCurrentStop={current_station_slot_index === slotIndex}
        effect={effect}
        isAffected={isAffected}
        firstAffectedIndex={
          effect === "station_closure"
            ? false
            : props.effect_region_slot_index_range[0] === slotIndex
        }
        abbreviate={doAbbreviate}
        labelTextClass={labelTextClass}
      />
    );
  });

  x += spaceBetween + SLOT_WIDTH;

  const [isDone, setIsDone] = useState(false);

  // Get the size of the diagram svg, excluding emphasis
  let dimensions = document.getElementById("line-map")?.getBoundingClientRect();
  let height = dimensions?.height ?? 0;
  let width = dimensions?.width ?? 0;

  useEffect(() => {
    // Get updated dimensions each time this hook runs
    dimensions = document.getElementById("line-map")?.getBoundingClientRect();
    height = dimensions?.height ?? 0;
    width = dimensions?.width ?? 0;

    if (svgHeight != 0 && width && height) {
      // if scaleFactor has already been applied to the line-map, we need to reverse that
      height = height / scaleFactor;
      width = width / scaleFactor;

      // First, scale x. Then, check if it needs abbreviating. Then scale y, given the abbreviation
      const xScaleFactor = 904 / width;

      const needsAbbreviating =
        height * xScaleFactor + getEmphasisHeight(xScaleFactor) > svgHeight &&
        !doAbbreviate;
      if (needsAbbreviating) {
        setDoAbbreviate(true);
        // now scale y, which requires re-running this effect
      } else {
        const yScaleFactor = (svgHeight - getEmphasisHeight(1)) / height
        const factor = Math.min(
          xScaleFactor,
          yScaleFactor
        );
        setScaleFactor(factor);
        setTimeout(() => {
          setIsDone(true);
        }, 200);
      }
    }
  }, [svgHeight, doAbbreviate]);

  // This is to center the diagram along the X axis
  const translateX = (width && (904 - width) / 2) || 0;
  
  // Next is to align the diagram at the top of the svg, which involves adjusting the SVG viewbox

  // If -${height} is used as the viewbox height, it looks like the line diagram text
  // pushed all the way to the bottom of the viewbox with just a tiny point of the
  // "You are Here" diamond sticking out. So, the parts that are cut off are the whole
  // height of the line diagram, and a little extra for the bottom of the "You are Here" diamond.

  // To calculate the height of that missing part, that is:
  // LINE_HEIGHT*scaleFactor/2 - MAX_ENDPOINT_HEIGHT*scaleFactor/2 + (hasEmphasis ? EMPHASIS_PADDING_TOP * scaleFactor : 0)

  // offset is parent container height minus all the stuff below the very top of the line diagram
  const viewBoxOffset = 
    height
    - (LINE_HEIGHT * scaleFactor) / 2
    - (MAX_ENDPOINT_HEIGHT * scaleFactor) / 2
    + (hasEmphasis ? EMPHASIS_PADDING_TOP * scaleFactor : 0)

  return (
    <svg
      // viewBoxOffset will always be > 0 by the time it's visible, but the console will
      // still log an error if it's a negative number when it's not-yet-visible
      viewBox={`0 ${-viewBoxOffset} 904 ${height + getEmphasisHeight(scaleFactor)}`}
      transform={`translate(${translateX})`}
      visibility={isDone ? "visible" : "hidden"}
    >
      <g transform={`translate(${L * scaleFactor} 0)`}>
        <g id="line-map" transform={`scale(${scaleFactor})`}>
          {effect !== "station_closure" && (
            <EffectBackgroundComponent
              effectRegionSlotIndexRange={props.effect_region_slot_index_range}
              effect={effect}
              spaceBetween={spaceBetween}
            />
          )}
          <EndSlotComponent
            slot={beginning}
            x={0}
            line={line}
            isCurrentStop={current_station_slot_index === 0}
            spaceBetween={spaceBetween}
            isAffected={
              effect === "station_closure"
                ? props.closed_station_slot_indices.includes(0)
                : props.effect_region_slot_index_range.includes(0)
            }
            effect={effect}
            isLeftSide={true}
          />
          {middleSlots}
          <EndSlotComponent
            slot={end as EndSlot}
            x={x}
            line={line}
            isCurrentStop={current_station_slot_index === slots.length - 1}
            spaceBetween={spaceBetween}
            isAffected={
              effect === "station_closure"
                ? props.closed_station_slot_indices.includes(slots.length - 1)
                : props.effect_region_slot_index_range.includes(
                    slots.length - 1
                  )
            }
            effect={effect}
            isLeftSide={false}
          />
        </g>
        {hasEmphasis && (
          <g
            id="alert-emphasis"
            transform={`translate(0, ${
              EMPHASIS_HEIGHT/2 // Half the height of the emphasis icon
              + LARGE_X_STOP_ICON_HEIGHT/2 * scaleFactor // Half the height of the largest closure icon, "you are here" octagon
              + 8 * scaleFactor // Emphasis padding
            })`}
          >
            <AlertEmphasisComponent
              effectRegionSlotIndexRange={props.effect_region_slot_index_range}
              spaceBetween={spaceBetween}
              effect={effect}
              scaleFactor={scaleFactor}
            />
          </g>
        )}
      </g>
    </svg>
  );
};

export { DisruptionDiagramData };

export default DisruptionDiagram;
