import React, { ComponentType, useEffect, useState } from "react";
import { classWithModifier, classWithModifiers } from "Util/util";

// TODO: Some of these svgs are a bit garbled
import LargeXOctagonBordered from "../../../../static/images/svgr_bundled/disruption_diagram/large-x-octagon-bordered.svg"
import SmallXOctagon from "../../../../static/images/svgr_bundled/disruption_diagram/small-x-octagon.svg"
import CurrentStopDiamond from "../../../../static/images/svgr_bundled/disruption_diagram/current-stop-diamond.svg"
import CurrentStopOpenDiamond from "../../../../static/images/svgr_bundled/disruption_diagram/current-stop-open-diamond.svg"
import ArrowLeftEndpoint from "../../../../static/images/svgr_bundled/disruption_diagram/arrow-left-endpoint.svg"
import ArrowRightEndpoint from "../../../../static/images/svgr_bundled/disruption_diagram/arrow-right-endpoint.svg"
import ShuttleBusIcon from "../../../../static/images/svgr_bundled/disruption_diagram/shuttle-emphasis-icon.svg"

const MAX_WIDTH = 904;
const SLOT_WIDTH = 24;
const LINE_HEIGHT = 24;
const EMPHASIS_HEIGHT = 80;
const EMPHASIS_PADDING_TOP = 8;
// L can vary based on arrow vs diamond (current stop). Would be nice if this was
// programmatic, but this works for now
const L = 27;
const R = 165;
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
  x: number;
  className?: string;
}

// TODO add comments about the translation choices
// TODO make -${(iconSize-LINE_HEIGHT) / 2} a function

// Special current stop icon for the red line: hollow red diamond
const CurrentStopOpenDiamondIcon: ComponentType<{x: number, iconSize: number}> = ({ x, iconSize }) => {
  const strokeWidth = 4;

  return (
    <g className="open-diamond" transform={`translate(${x - (iconSize + strokeWidth) / 2} -${(iconSize-LINE_HEIGHT) / 2})`}>
      <CurrentStopOpenDiamond width={iconSize} height={iconSize} />
    </g>
  );
};

// Current stop icon for all other lines: solid red diamond
const CurrentStopDiamondIcon: ComponentType<{x: number, iconSize: number}> = ({ x, iconSize }) => {
  const strokeWidth = 4;

  return (
    <g className="solid-diamond" transform={`translate(${x - (iconSize + strokeWidth) / 2} -${(iconSize-LINE_HEIGHT) / 2})`}>
      <CurrentStopDiamond width={iconSize} height={iconSize} />
    </g>
  );
};

// This is the x-octagon without a border
const SmallXStopIcon: ComponentType<{x: number, iconSize: number}> = ({ x, iconSize }) => {
  return (
    // Translate needs to be the given x shifted by half the size of the icon, and y needs to be shifted up half its
    // iconsize and half the thickness of the line diagram itself
    <g className="small-x-stop" transform={`translate(${x - iconSize / 2} -${(iconSize-LINE_HEIGHT) / 2})`}>
      <SmallXOctagon width={iconSize} height={iconSize} />
    </g>
  );
};

// This is the x-octagon with a border
const LargeXStopIcon: ComponentType<{x: number, iconSize: number, color?: string}> = ({ x, iconSize, color }) => {
  return (
    // Translate needs to be the given x shifted by half the size of the icon, and y needs to be shifted up half its
    // iconsize and half the thickness of the line diagram itself
    <g className="large-x-stop" transform={`translate(${x - iconSize / 2} -${(iconSize-LINE_HEIGHT) / 2})`}>
      <LargeXOctagonBordered color={color} width={iconSize} height={iconSize} />
    </g>
  );
};

// Basic template for a Circle Icon
const CircleStopIcon: ComponentType<{x: number, r: number, className: string, strokeWidth: number}> = ({ x, r, className, strokeWidth }) => (
  <circle
    cx={x}
    cy={LINE_HEIGHT / 2}
    r={r}
    fill="white"
    className={className}
    strokeWidth={strokeWidth}
  />
);

const CircleShuttlingStopIcon: ComponentType<IconProps> = ({ x }) => (
  <CircleStopIcon x={x} r={10} className="shuttle-stop" strokeWidth={4} />
);

const CircleStopIconEndpoint: ComponentType<{x: number, className: string}> = ({ x, className }) => (
  <CircleStopIcon x={x} r={20} className={className} strokeWidth={8} />
);

const LeftArrowEndpoint: ComponentType<IconProps> = ({ x, className }) => (
  <g transform={`translate(${x})`} >
    <ArrowLeftEndpoint className={className} />
  </g>
);

const RightArrowEndpoint: ComponentType<IconProps> = ({ x, className }) => (
  <g transform={`translate(${x - 1})`} >
    <ArrowRightEndpoint className={className} />
  </g>
);

const getEndpointLabel = (labelID: string, x: number, isArrow: boolean) => {
  let labelParts = endLabelIDMap[labelID];
  if (labelParts.length === 1) {
    return (
      <text
        className="label--endpoint"
        transform={`translate(${x} -32) rotate(-45)`}
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
          transform={`translate(${x} -32) rotate(-45)`}
        >
          {isArrow && <tspan className="label">to </tspan>}
          {labelParts[0]}
        </text>
        <text
          className="label--endpoint"
          transform={`translate(${x + 45} -32) rotate(-45)`}
        >
          {labelParts[1]}
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
  leftSide: boolean;
  x: number
}

const EndSlotComponent: ComponentType<EndSlotComponentProps> = ({
  slot,
  line,
  isCurrentStop,
  isAffected,
  effect,
  spaceBetween,
  leftSide,
  x
}) => {
  let icon;
  if (slot.type === "arrow") {
    icon = leftSide === true ?
      // TODO explain 5
      <LeftArrowEndpoint x={5} className={classWithModifier("end-slot__arrow", line)} />
      : <RightArrowEndpoint x={x} className={classWithModifier("end-slot__arrow", line)} />
  } else if (isAffected && effect === "station_closure" || effect === "suspension") {
    icon = <LargeXStopIcon x={x} iconSize={61} />
  } else if (isCurrentStop && line === "red") {
    icon = <CurrentStopOpenDiamondIcon x={x} iconSize={64} />
  } else if (isCurrentStop) {
    icon = <CurrentStopDiamondIcon x={x} iconSize={64} />
  } else {
      const modifiers = [line.toString()];
      if (isAffected) {
        modifiers.push("affected");
      }
      icon = <CircleStopIconEndpoint x={x} className={classWithModifiers("end-slot__icon", modifiers)} />
  }

  let background;
  if (!isAffected && leftSide || effect === "station_closure" && leftSide) {
    background = (
      <rect
        className={classWithModifier("end-slot__arrow", line)}
        width={SLOT_WIDTH / 2 + spaceBetween}
        height={LINE_HEIGHT}
        fill={line}
        x={L + SLOT_WIDTH / 2}
      />
    );
  } else {
    background = <></>;
  }

  return (
    <>
      {background}
      {icon}
      {getEndpointLabel(slot.label_id, x, slot.type === "arrow")}
    </>
  );
}

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
        width={SLOT_WIDTH + spaceBetween}
        height={LINE_HEIGHT}
        x={x}
      />
    );
  }

  let icon;
  if (slot.show_symbol) {
    if (isCurrentStop) {
      if (isAffected && effect in ["station_closure", "suspension"]) {
        icon = (
          <LargeXStopIcon
            x={x}
            iconSize={48}
            color="#ee2e24"
          />
        );
      } else {
        icon =
          line === "red" ? (
            <CurrentStopOpenDiamondIcon x={x} iconSize={52} />
          ) : (
            <CurrentStopDiamondIcon x={x} iconSize={52} />
          );
      }
    } else {
      if (isAffected && !firstAffectedIndex) {
        switch (effect) {
          case "suspension":
            icon = <SmallXStopIcon x={x} iconSize={24} />;
            break;
          case "station_closure":
            icon = <SmallXStopIcon x={x} iconSize={48} />;
            break;
          case "shuttle":
            // TODO: where in the designs is this?
            if (label !== "…" && label.full === "Beaconsfield") {
              icon = <SmallXStopIcon x={x} iconSize={30} />;
            } else {
              icon = <CircleShuttlingStopIcon x={x} />;
            }
        }
      } else {
        icon = (
          <CircleStopIcon
            x={x}
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
    <>
      {background}
      {icon}
      {label === "…" ? (
        <text
          className={classWithModifier(`label-${labelTextClass}`, textModifier)}
          transform={`translate(${x - 12} -32)`}
        >
          {" "}
          {label}{" "}
        </text>
      ) : (
        <text
          className={classWithModifier(`label-${labelTextClass}`, textModifier)}
          transform={`translate(${x} -32) rotate(-45)`}
        >
          {abbreviate || label.full === "Massachusetts Avenue"
            ? label.abbrev
            : label.full}
        </text>
      )}
    </>
  );
};

interface EffectBackgroundComponentProps {
  effectRegionSlotIndexRange:
    | [range_start: number, range_end: number]
    | number[];
  effect: Effect;
  spaceBetween: number;
}

const EffectBackgroundComponent: ComponentType<
  EffectBackgroundComponentProps
> = ({ spaceBetween, effect, effectRegionSlotIndexRange }) => {
  const rangeStart = effectRegionSlotIndexRange[0];
  const rangeEnd = effectRegionSlotIndexRange[1];

  const x1 = rangeStart * (spaceBetween + SLOT_WIDTH) + L;
  const x2 = (spaceBetween + SLOT_WIDTH) * rangeEnd + L;
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
  } else if (effect === "suspension") {
    background = (
      <rect
        width={x2 - x1 + SLOT_WIDTH}
        height={heightOfBackground}
        x={x1}
        y={heightOfBackground / 4}
        fill="#AEAEAE"
      />
    );
  } else {
    background = <></>;
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

  const x1 = (rangeStart * (spaceBetween + SLOT_WIDTH) + L) * scaleFactor;
  const x2 = ((spaceBetween + SLOT_WIDTH) * rangeEnd + L) * scaleFactor;

  const middleOfLine = (x2 - x1) / 2 + x1;
  const endLinesHeight = 24;

  let icon;
  if (effect === "shuttle") {
    // Why are these yet another instance of the same icons we've already worked with??
    icon = (
      <g transform={`translate(${
            middleOfLine - EMPHASIS_HEIGHT / 2
            } ${-endLinesHeight})`}>
        <ShuttleBusIcon />
      </g>
    )
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
            strokeWidth="8"
            strokeLinecap="round"
          />
          <path
            d={`M${x1} ${endLinesHeight / 2}H${x2}`}
            stroke="#737373"
            strokeWidth="8"
            strokeLinecap="round"
          />
          <path
            d={`M${x2} 0L${x2} ${endLinesHeight}`}
            stroke="#737373"
            strokeWidth="8"
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
  const { 0: beginning, [slots.length - 1]: end, ...middle } = slots;
  const hasEmphasis = effect !== "station_closure";
  const calculated_emphasis_height = hasEmphasis ? EMPHASIS_HEIGHT + EMPHASIS_PADDING_TOP : 0;
  const labelTextClass = slots.length > 12 ? "small" : "large";

  let x = 0;
  const middleSlots = Object.values(middle).map((s, i) => {
    x = (spaceBetween + SLOT_WIDTH) * (i + 1) + L;
    const slot = s as MiddleSlot;
    const key = slot.label === "…" ? i : slot.label.full;
    const isAffected =
      effect === "station_closure"
        ? props.closed_station_slot_indices.includes(i + 1)
        : i + 1 >= props.effect_region_slot_index_range[0] &&
          i + 1 <= props.effect_region_slot_index_range[1] - 1;

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
        firstAffectedIndex={
          effect === "station_closure"
            ? false
            : props.effect_region_slot_index_range[0] === i + 1
        }
        abbreviate={doAbbreviate}
        labelTextClass={labelTextClass}
      />
    );
  });

  x += spaceBetween + SLOT_WIDTH;

  const [isDone, setIsDone] = useState(false);
  const [isDoneScaling, setIsDoneScaling] = useState(false);
  const [lineMapHeight, setLineMapHeight] = useState(0);

  useEffect(() => {
    const dimensions = document
      .getElementById("line-map")
      ?.getBoundingClientRect();

    const height = dimensions?.height;
    const width = dimensions?.width;

    // Hardcoding what it SHOULD be returning
    const newSvgHeight = 309// document.getElementById("disruption-diagram-container")?.getBoundingClientRect()?.height;

    if (!isDoneScaling && width && newSvgHeight && height) {
      // Scale diagram up or down so width < 904px and height < total height
      const factor = Math.min(904 / width, (newSvgHeight - calculated_emphasis_height) / height)
      setScaleFactor(factor);
      setIsDoneScaling(true);
    } else if (!isDone && isDoneScaling) {
      // If the height of the line map + emphasis (if present) is still too tall,
      // abbreviate station names.
      if (height && height + (hasEmphasis ? EMPHASIS_HEIGHT : 0) > svgHeight) {
        setDoAbbreviate(true);
      }

      setIsDone(true);
    }
  });

  // Get the finalized height of the line map after scaling and abbreviations
  useEffect(() => {
    const dimensions = document
      .getElementById("line-map")
      ?.getBoundingClientRect();

    const height = dimensions?.height;

    if (isDone && height) {
      setLineMapHeight(height);
    }
  }, [isDone]);

  const canvasSize = 904
  const height = document.getElementById("disruption-diagram-container")?.getBoundingClientRect()?.height;

  // 30 = max icon height / 2
  const viewBoxOffset = height ? height - 30 - calculated_emphasis_height : 0;

  return (
    <svg viewBox={`0 -${viewBoxOffset} ${canvasSize} ${canvasSize}`}>
      <g
        id="line-map"
        // Center the axis right on the diagram line
        transform-origin={`0 ${LINE_HEIGHT/2}`}
        transform={`scale(${scaleFactor})`}
        visibility={isDone ? "visible" : "hidden"}
      >
        <EffectBackgroundComponent
          effectRegionSlotIndexRange={
            effect === "station_closure"
              ? props.closed_station_slot_indices
              : props.effect_region_slot_index_range
          }
          effect={effect}
          spaceBetween={spaceBetween}
        />
        <EndSlotComponent
          slot={beginning}
          x={L}
          line={line}
          isCurrentStop={current_station_slot_index === 0}
          spaceBetween={spaceBetween}
          isAffected={
            effect === "station_closure"
              ? props.closed_station_slot_indices.includes(0)
              : props.effect_region_slot_index_range.includes(0)
          }
          effect={effect}
          leftSide={true}
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
              : props.effect_region_slot_index_range.includes(slots.length - 1)
          }
          effect={effect}
          leftSide={false}
        />
      </g>
      {hasEmphasis && (
        <g
          id="alert-emphasis"
          transform={`translate(0, ${EMPHASIS_HEIGHT / 2 + LINE_HEIGHT / 2})`}
          visibility={isDone ? "visible" : "hidden"}
        >
          <AlertEmphasisComponent
            effectRegionSlotIndexRange={props.effect_region_slot_index_range}
            spaceBetween={spaceBetween}
            effect={effect}
            scaleFactor={scaleFactor}
          />
        </g>
      )}
    </svg>
  );
};

export { DisruptionDiagramData };

export default DisruptionDiagram;
