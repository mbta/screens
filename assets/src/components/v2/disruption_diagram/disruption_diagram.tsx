import { classWithModifier, classWithModifiers } from "Util/util";
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

interface IconProps {
  x: number;
  className?: string;
}

const CurrentStopIconRedLine: ComponentType<IconProps> = ({ x }) => (
  <>
    <path
      transform={`translate(${x - SLOT_WIDTH} -4)`}
      d="M32.6512 3.92661C30.0824 1.3578 25.9176 1.3578 23.3488 3.92661L3.92661 23.3488C1.3578 25.9176 1.3578 30.0824 3.92661 32.6512L23.3488 52.0734C25.9176 54.6422 30.0824 54.6422 32.6512 52.0734L52.0734 32.6512C54.6422 30.0824 54.6422 25.9176 52.0734 23.3488L32.6512 3.92661Z"
      className="middle-slot__background--red"
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

const CurrentStopIcon: ComponentType<IconProps> = ({ x }) => (
  <>
    <path
      transform={`translate(${x - SLOT_WIDTH} -4)`}
      d="M3.15665 25.2076C1.61445 26.7498 1.61445 29.2502 3.15665 30.7924L25.2076 52.8434C26.7498 54.3856 29.2502 54.3856 30.7924 52.8434L52.8434 30.7924C54.3856 29.2502 54.3856 26.7498 52.8434 25.2076L30.7924 3.15668C29.2502 1.61448 26.7498 1.61448 25.2076 3.15668L3.15665 25.2076Z"
      fill="#EE2E24"
      stroke="#E6E4E1"
      strokeWidth="4"
    />
  </>
);

const CurrentStopIconEndpoint: ComponentType<IconProps> = ({ x }) => (
  <path
    transform={`translate(${x - SLOT_WIDTH} -8)`}
    d="M3.13388 28.7629C1.74155 30.1552 1.74155 32.4126 3.13388 33.8049L28.2253 58.8964C29.6176 60.2887 31.8751 60.2887 33.2674 58.8964L58.3588 33.8049C59.7511 32.4126 59.7511 30.1552 58.3588 28.7629L33.2674 3.67141C31.8751 2.27909 29.6176 2.27909 28.2253 3.67141L3.13388 28.7629Z"
    fill="#EE2E24"
    stroke="#E6E4E1"
    strokeWidth="3.58209"
  />
);

const SuspensionStopIcon: ComponentType<IconProps> = ({ x }) => (
  <>
    <rect x={x - 6} y="16" width="18" height="16" fill="white" />
    <path
      transform={`translate(${x - 12} 9)`}
      fillRule="evenodd"
      clipRule="evenodd"
      d="M8.93886 0C8.76494 0 8.5985 0.0707868 8.47786 0.196069L0.178995 8.81412C0.0641567 8.93338 0 9.09249 0 9.25805V21.0682C0 21.238 0.0674284 21.4008 0.187452 21.5208L8.47922 29.8125C8.59924 29.9326 8.76202 30 8.93176 30H21.0611C21.2351 30 21.4015 29.9292 21.5221 29.8039L29.821 21.1859C29.9358 21.0666 30 20.9075 30 20.7419V8.93176C30 8.76202 29.9326 8.59924 29.8125 8.47922L21.5208 0.187452C21.4008 0.0674284 21.238 0 21.0682 0H8.93886ZM7.5935 10.0066C7.34658 10.2576 7.34866 10.6608 7.59816 10.9091L11.957 15.248L7.59623 19.6793C7.34824 19.9313 7.35156 20.3366 7.60365 20.5845L9.73397 22.6794C9.98593 22.9272 10.391 22.9239 10.6389 22.672L15 18.2404L19.3611 22.672C19.609 22.9239 20.0141 22.9272 20.266 22.6794L22.3964 20.5845C22.6484 20.3366 22.6518 19.9313 22.4038 19.6793L18.043 15.248L22.4018 10.9091C22.6513 10.6608 22.6534 10.2576 22.4065 10.0066L20.2613 7.82685C20.0124 7.5739 19.6052 7.5718 19.3537 7.82217L15 12.1559L10.6463 7.82217C10.3948 7.5718 9.98758 7.5739 9.73865 7.82685L7.5935 10.0066Z"
      fill="#171F26"
    />
  </>
);

const StationClosureStopIcon: ComponentType<IconProps> = ({ x }) => (
  <path
    transform={`translate(${x - SLOT_WIDTH} -2)`}
    d="M22.6628 27.0001L23.9119 25.7308L22.6498 24.4744L17.0202 18.8706L18.8677 16.9933L24.4828 22.5826L25.7463 23.8404L27.0099 22.5826L32.625 16.9933L34.4725 18.8706L28.8429 24.4744L27.5807 25.7308L28.8298 27.0001L34.4649 32.7261L32.6588 34.5021L27.0229 28.7751L25.7463 27.4779L24.4698 28.7751L18.8338 34.5021L17.0278 32.7261L22.6628 27.0001ZM35.0884 18.2575L35.0876 18.2583L35.0884 18.2575ZM19.4568 35.1147L19.456 35.114L19.4568 35.1147ZM3.22013 15.2827L4.51025 16.5251L3.22013 15.2827C2.73421 15.7873 2.46274 16.4606 2.46274 17.1611V34.0832C2.46274 34.8014 2.74805 35.4902 3.25592 35.9981L15.1366 47.8788L16.4031 46.6124L15.1367 47.8788C15.6445 48.3867 16.3333 48.672 17.0515 48.672H34.4309C35.1669 48.672 35.8711 48.3725 36.3816 47.8424L48.2725 35.4941C48.7585 34.9895 49.0299 34.3162 49.0299 33.6157V16.6936C49.0299 15.9754 48.7446 15.2866 48.2368 14.7788L46.9703 16.0452L48.2367 14.7787L36.356 2.898C35.8481 2.39014 35.1593 2.10483 34.4411 2.10483H17.0617C16.3258 2.10483 15.6215 2.40435 15.111 2.93447L3.22013 15.2827Z"
    fill="#171F26"
    stroke="#E6E4E1"
    strokeWidth="3.58209"
  />
);

const ShuttleStopIcon: ComponentType<IconProps> = ({ x }) => (
  <circle cx={x} cy="24" r="10" fill="white" stroke="#171F26" strokeWidth="4" />
);

const StopIcon: ComponentType<IconProps> = ({ x, className }) => (
  <circle
    cx={x}
    cy="24"
    r="10"
    fill="white"
    className={className}
    strokeWidth="4"
  />
);

const StopIconEndpoint: ComponentType<IconProps> = ({ x, className }) => (
  <circle
    cx={x}
    cy="24"
    r="20"
    fill="white"
    className={className}
    strokeWidth="8"
  />
);

const ArrowEndpoint: ComponentType<IconProps> = ({ x, className }) => (
  <path
    transform={`translate(${x} 12)`}
    width={204}
    d="M0 24V0H59.446C59.8085 0 60.1642 0.0985159 60.475 0.285014L77.1417 10.285C78.4364 11.0618 78.4364 12.9382 77.1417 13.715L60.475 23.715C60.1642 23.9015 59.8085 24 59.446 24H0Z"
    className={className}
  />
);

interface EndSlotComponentProps {
  slot: EndSlot;
  line: LineColor;
  isCurrentStop: boolean;
}

const FirstSlotComponent: ComponentType<
  EndSlotComponentProps & {
    spaceBetween: number;
    isAffected: boolean;
    effect: string;
  }
> = ({ slot, line, spaceBetween, isAffected, effect }) => {
  let icon;
  if (slot.type === "arrow") {
    icon = (
      <path
        className={classWithModifier("end-slot__arrow", line)}
        transform="translate(0 12)"
        d="M35 0V24L19.554 24C19.1915 24 18.8358 23.9015 18.525 23.715L1.85831 13.715C0.563633 12.9382 0.563633 11.0618 1.85831 10.285L18.525 0.285015C18.8358 0.0985165 19.1915 0 19.554 0L35 0Z"
        fill={line}
      />
    );
  } else {
    const modifiers = [line.toString()];
    if (isAffected) {
      modifiers.push("affected");
    }
    icon = (
      <StopIconEndpoint
        className={classWithModifiers("end-slot__icon", modifiers)}
        x={L}
      />
    );
  }

  let background;
  if (!isAffected || effect === "station_closure") {
    background = (
      <rect
        className={classWithModifier("end-slot__arrow", line)}
        width={SLOT_WIDTH / 2 + spaceBetween}
        height={LINE_HEIGHT}
        fill={line}
        x={L + SLOT_WIDTH / 2}
        y="12"
      />
    );
  } else {
    background = <></>;
  }

  return (
    <>
      {background}
      {icon}
    </>
  );
};

const LastSlotComponent: ComponentType<
  EndSlotComponentProps & { x: number }
> = ({ slot, line, x, isCurrentStop }) => {
  if (slot.type === "arrow") {
    return (
      <ArrowEndpoint
        x={x}
        className={classWithModifier("end-slot__arrow", line)}
      />
    );
  } else if (isCurrentStop) {
    return <CurrentStopIconEndpoint x={x} />;
  } else {
    return (
      <StopIconEndpoint
        x={x}
        className={classWithModifier("end-slot__icon", line)}
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
  firstAffectedIndex: boolean;
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
}) => {
  let background;
  // Background for these effects is drawn in EffectBackgroundComponent.
  if (isAffected && effect !== "station_closure") {
    background = <></>;
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
      icon =
        line === "red" ? (
          <CurrentStopIconRedLine x={x} />
        ) : (
          <CurrentStopIcon x={x} />
        );
    } else {
      if (isAffected && !firstAffectedIndex) {
        switch (effect) {
          case "suspension":
            icon = <SuspensionStopIcon x={x} />;
            break;
          case "station_closure":
            icon = <StationClosureStopIcon x={x} />;
            break;
          case "shuttle":
            icon = <ShuttleStopIcon x={x} />;
        }
      } else {
        icon = (
          <StopIcon
            x={x}
            className={classWithModifier("middle-slot__icon", line)}
          />
        );
      }
    }
  } else {
    icon = <></>;
  }

  return (
    <>
      {background}
      {icon}
    </>
  );
};

interface EffectBackgroundComponentProps {
  effectRegionSlotIndexRange:
    | [range_start: number, range_end: number]
    | number[];
  effect: string;
  spaceBetween: number;
}

const EffectBackgroundComponent: ComponentType<
  EffectBackgroundComponentProps
> = ({ spaceBetween, effect, effectRegionSlotIndexRange }) => {
  const rangeStart = effectRegionSlotIndexRange[0];
  const rangeEnd = effectRegionSlotIndexRange[1];

  const x1 = rangeStart * (spaceBetween + SLOT_WIDTH) + L;
  const x2 = (spaceBetween + SLOT_WIDTH) * (rangeEnd + 1);

  let background;
  if (effect === "shuttle") {
    background = (
      <line
        x1={x1}
        y1="24"
        x2={x2}
        y2="24"
        height="16"
        strokeWidth={16}
        stroke="black"
        strokeDasharray="12 6"
      />
    );
  } else if (effect === "suspension") {
    background = (
      <rect width={x2 - SLOT_WIDTH} height="16" x={x1} y="16" fill="#AEAEAE" />
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
  effect: "suspension" | "shuttle" | "station_closure";
}

const AlertEmphasisComponent: ComponentType<AlertEmphasisComponentProps> = ({
  effectRegionSlotIndexRange,
  spaceBetween,
  effect,
}) => {
  if (effect === "station_closure") return <></>;

  const rangeStart = effectRegionSlotIndexRange[0];
  const rangeEnd = effectRegionSlotIndexRange[1];

  const x1 = rangeStart * (spaceBetween + SLOT_WIDTH) + L;
  const x2 = (spaceBetween + SLOT_WIDTH) * (rangeEnd - rangeStart + 1);
  const middleOfLine = (x1 + x2 + (x1 - L / 2)) / 2;
  const widthOfBackground = 40;

  let icon;
  if (effect === "shuttle") {
    icon = (
      <>
        <circle
          cx={middleOfLine}
          cy="16"
          r={widthOfBackground}
          fill="#171F26"
        />
        <path
          transform={`translate(${middleOfLine - widthOfBackground} -24)`}
          fillRule="evenodd"
          clipRule="evenodd"
          d="M60.8695 37.5334L58.842 21.6673C58.327 18.8044 56.513 17.6872 53.8141 16.5156C49.3915 14.9398 44.7285 14.0896 40.017 14C35.2983 14.0906 30.628 14.9408 26.1974 16.5156C23.532 17.6651 21.7178 18.8039 21.1691 21.6668L19.1309 37.5334V59.4837H22.709V63.3065C22.7138 64.8769 24.0275 66.1487 25.6492 66.153C27.2708 66.1484 28.5841 64.8765 28.5889 63.3062V59.4834H51.5189V63.3062C51.5111 64.3282 52.0697 65.2758 52.9824 65.789C53.8951 66.3022 55.0219 66.3022 55.9346 65.789C56.8473 65.2758 57.4059 64.3282 57.3982 63.3062V59.4834H60.87L60.8695 37.5334ZM31.429 18.0156H48.6755C49.4054 18.0156 49.997 18.5886 49.997 19.2954C49.997 20.0022 49.4054 20.5751 48.6755 20.5751H31.429C30.6991 20.5751 30.1074 20.0022 30.1074 19.2954C30.1074 18.5886 30.6991 18.0156 31.429 18.0156ZM24.5181 24.5431L22.839 37.069C22.8167 37.2128 22.8167 37.359 22.839 37.5028C22.8175 37.9344 22.9743 38.3566 23.2748 38.676C23.5752 38.9955 23.9947 39.186 24.4404 39.2055H55.7192C56.1641 39.2101 56.5924 39.0417 56.9081 38.7379C57.2237 38.4341 57.4002 38.0204 57.3982 37.5895V37.5028C57.4207 37.359 57.4207 37.2128 57.3982 37.069L55.7192 24.5431C55.5841 23.7547 54.8758 23.1793 54.0506 23.1876H26.1971C25.3697 23.179 24.6582 23.7534 24.5181 24.5431ZM25.6476 52.6951C23.9189 52.6982 22.515 51.3436 22.5117 49.6696C22.5085 47.9956 23.9072 46.636 25.6358 46.6328C27.3645 46.6296 28.7686 47.984 28.772 49.658C28.7741 50.4621 28.446 51.2341 27.86 51.8038C27.2739 52.3735 26.478 52.6941 25.6476 52.6951ZM54.4601 46.6328C52.733 46.6339 51.3332 47.9895 51.332 49.662C51.3309 51.3345 52.7289 52.6918 54.4555 52.6951C55.2881 52.6973 56.0872 52.3781 56.6759 51.808C57.2647 51.238 57.5945 50.4642 57.5923 49.658C57.5889 47.9855 56.1872 46.6317 54.4601 46.6328Z"
          fill="white"
        />
      </>
    );
  } else if (effect === "suspension") {
    icon = (
      <>
        <rect
          x={middleOfLine - 35}
          y="-6"
          width={60}
          height={45}
          fill="white"
        />
        <path
          transform={`translate(${middleOfLine - widthOfBackground} -24)`}
          fill-rule="evenodd"
          clip-rule="evenodd"
          d="M23.837 0C23.3732 0 22.9293 0.188765 22.6076 0.522852L0.47732 23.5043C0.171085 23.8223 0 24.2467 0 24.6881V56.182C0 56.6346 0.179809 57.0687 0.499871 57.3888L22.6112 79.5001C22.9313 79.8202 23.3654 80 23.818 80H56.163C56.6268 80 57.0707 79.8112 57.3924 79.4771L79.5227 56.4957C79.8289 56.1777 80 55.7534 80 55.3119V23.818C80 23.3654 79.8202 22.9313 79.5001 22.6112L57.3888 0.499871C57.0687 0.179809 56.6346 0 56.182 0H23.837ZM20.2493 26.6844C19.5909 27.3535 19.5964 28.4288 20.2618 29.091L31.8854 40.6614L20.2566 52.478C19.5953 53.15 19.6042 54.2309 20.2764 54.892L25.9573 60.4784C26.6291 61.1391 27.7094 61.1303 28.3703 60.4586L40 48.6411L51.6297 60.4586C52.2906 61.1303 53.3708 61.1391 54.0427 60.4784L59.7236 54.892C60.3958 54.2309 60.4047 53.15 59.7434 52.478L48.1146 40.6614L59.7383 29.091C60.4036 28.4288 60.4091 27.3535 59.7507 26.6844L54.0303 20.8716C53.3665 20.1971 52.2805 20.1915 51.6098 20.8591L40 32.4157L28.3902 20.8591C27.7195 20.1915 26.6335 20.1971 25.9697 20.8716L20.2493 26.6844Z"
          fill="#171F26"
        />
      </>
    );
  }

  return (
    <g transform="translate(5, 100)">
      <path
        d={`M${x1 - L / 2} 4L${x1 - L / 2} 28`}
        stroke="#737373"
        strokeWidth="8"
        strokeLinecap="round"
      />
      <path
        d={`M${x1 - L / 2} 16H${x1 + x2}`}
        stroke="#737373"
        strokeWidth="8"
        strokeLinecap="round"
      />
      <path
        d={`M${x1 + x2} 4L${x1 + x2} 28`}
        stroke="#737373"
        strokeWidth="8"
        strokeLinecap="round"
      />
      {icon}
    </g>
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
  const { slots, current_station_slot_index, line, effect } = props;
  const numStops = slots.length;
  const spaceBetween = Math.min(
    60,
    (W - SLOT_WIDTH * numStops) / (numStops - 1)
  );
  const { 0: beginning, [slots.length - 1]: end, ...middle } = slots;
  let x = 0;
  const middleSlots = Object.values(middle).map((s, i) => {
    x = (spaceBetween + SLOT_WIDTH) * (i + 1) + L;
    const slot = s as MiddleSlot;
    const key = slot.label === "…" ? i : slot.label.full;
    const isAffected =
      effect === "station_closure"
        ? props.closed_station_slot_indices.includes(i + 1)
        : i + 1 >= props.effect_region_slot_index_range[0] &&
          i + 1 <= props.effect_region_slot_index_range[1];

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
      />
    );
  });

  x += spaceBetween + SLOT_WIDTH;

  return (
    <div style={{ width: "904px", height: "308px" }}>
      <svg
        width="904px"
        height="308px"
        version="1.1"
        xmlns="http://www.w3.org/2000/svg"
        style={{ padding: "24px" }}
      >
        <g transform="translate(12, 100)">
          <EffectBackgroundComponent
            effectRegionSlotIndexRange={
              effect === "station_closure"
                ? props.closed_station_slot_indices
                : props.effect_region_slot_index_range
            }
            effect={effect}
            spaceBetween={spaceBetween}
          />
          <FirstSlotComponent
            slot={beginning}
            line={line}
            isCurrentStop={current_station_slot_index === 0}
            spaceBetween={spaceBetween}
            isAffected={
              effect === "station_closure"
                ? props.closed_station_slot_indices.includes(0)
                : props.effect_region_slot_index_range.includes(0)
            }
            effect={effect}
          />

          {middleSlots}
          <LastSlotComponent
            slot={end as EndSlot}
            x={x}
            line={line}
            isCurrentStop={current_station_slot_index === slots.length - 1}
          />
          <AlertEmphasisComponent
            effectRegionSlotIndexRange={
              effect === "station_closure"
                ? props.closed_station_slot_indices
                : props.effect_region_slot_index_range
            }
            spaceBetween={spaceBetween}
            effect={effect}
          />
        </g>
      </svg>
    </div>
  );
};

export { ContinuousDisruptionDiagram, DiscreteDisruptionDiagram };

export default DisruptionDiagram;
