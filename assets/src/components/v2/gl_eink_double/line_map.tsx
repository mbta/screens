import React from "react";

import { classWithModifier } from "Util/util";

const WIDTH = 374;
const HEIGHT = 1312;

const STOP_SPACING = 112;
const LEFT_MARGIN = 84;
const LINE_WIDTH = 40;
const STOP_RADIUS = 14;
const BIG_STOP_RADIUS = 30;
const TOP_MARGIN = 124;
const TEXT_LEFT_MARGIN = 18;
const TEXT_TOP_MARGIN = 10;
const VEHICLE_ICON_SIZE = 44;
const SCHEDULED_DEPARTURE_SIZE = 192;
const MAXIMUM_STOP_LABEL_LENGTH = 16;

const abbreviateStop = (stop) => {
  if (stop === "Heath Street") {
    return "Heath St.";
  }

  return stop;
};

// This function splits the label into two parts as close to the middle as possible.
// Will only split on a space.
const splitLabel = (labelText: string) => {
  let middle = Math.floor(labelText.length / 2);
  let before = labelText.lastIndexOf(" ", middle);
  let after = labelText.indexOf(" ", middle + 1);

  if (middle - before < after - middle) {
    middle = before;
  } else {
    middle = after;
  }

  return [labelText.substring(0, middle), labelText.substring(middle + 1)];
};

const BaseMapFutureTerminal = () => {
  return (
    <circle
      cx={LEFT_MARGIN + LINE_WIDTH / 2}
      cy={TOP_MARGIN}
      r={BIG_STOP_RADIUS}
      className="line-map--future"
    />
  );
};

const BaseMapFutureArrow = () => {
  const arrowHeight = LINE_WIDTH / 2;
  const lineHeight = 72;

  const pathData = [
    "M",
    LEFT_MARGIN,
    TOP_MARGIN,
    "L",
    LEFT_MARGIN,
    TOP_MARGIN - lineHeight,
    "L",
    LEFT_MARGIN + LINE_WIDTH / 2,
    TOP_MARGIN - (lineHeight + arrowHeight),
    "L",
    LEFT_MARGIN + LINE_WIDTH,
    TOP_MARGIN - lineHeight,
    "L",
    LEFT_MARGIN + LINE_WIDTH,
    TOP_MARGIN,
    "Z",
  ].join(" ");

  return <path d={pathData} className="line-map--future" />;
};

const BaseMapFuture = ({ stops }) => {
  const numFutureStops = stops.findIndex((stop) => stop.current);

  return (
    <>
      <rect
        x={LEFT_MARGIN}
        y={TOP_MARGIN}
        width={LINE_WIDTH}
        height={STOP_SPACING * numFutureStops}
        className="line-map--future"
      />
      {stops[0].terminal ? <BaseMapFutureTerminal /> : <BaseMapFutureArrow />}
    </>
  );
};

const BaseMapCurrent = ({ stops }) => {
  const numFutureStops = stops.findIndex((stop) => stop.current);

  return (
    <circle
      cx={LEFT_MARGIN + LINE_WIDTH / 2}
      cy={TOP_MARGIN + STOP_SPACING * numFutureStops}
      r={BIG_STOP_RADIUS}
      className="line-map--future"
    />
  );
};

const BaseMapPast = ({ stops }) => {
  const numStops = stops.length;
  const numFutureStops = stops.findIndex((stop) => stop.current);
  const numPastStops = numStops - (numFutureStops + 1);

  let height;
  if (stops[stops.length - 1].terminal) {
    height = STOP_SPACING * numPastStops;
  } else {
    height = HEIGHT - (TOP_MARGIN + STOP_SPACING * numFutureStops);
  }

  return (
    <>
      <rect
        x={LEFT_MARGIN}
        y={TOP_MARGIN + STOP_SPACING * numFutureStops}
        width={LINE_WIDTH}
        height={height}
        className="line-map--past"
      />

      {stops[stops.length - 1].terminal && (
        <circle
          cx={LEFT_MARGIN + LINE_WIDTH / 2}
          cy={TOP_MARGIN + STOP_SPACING * (numStops - 1)}
          r={BIG_STOP_RADIUS}
          className="line-map--past"
        />
      )}
    </>
  );
};

const BaseMapStops = ({ stops }) => {
  return (
    <>
      {stops.map(({ label, downstream, current, terminal }, i) => {
        const stopIcon = (
          <circle
            cx={LEFT_MARGIN + LINE_WIDTH / 2}
            cy={TOP_MARGIN + STOP_SPACING * i}
            r={STOP_RADIUS}
            className="line-map__stop"
          />
        );

        let stopLabel = null;
        let labelText = abbreviateStop(label);
        if (downstream || current || terminal) {
          let modifier;
          if (current && terminal) {
            modifier = "current-terminal";
            labelText = labelText.toUpperCase();
          } else if (current) {
            modifier = "current";
          } else if (!downstream && !current) {
            modifier = "past";
          }

          if (labelText.length > MAXIMUM_STOP_LABEL_LENGTH) {
            let labelParts = splitLabel(labelText);
            stopLabel = (
              <text
                x={LEFT_MARGIN + LINE_WIDTH + TEXT_LEFT_MARGIN}
                y={TEXT_TOP_MARGIN + TOP_MARGIN + STOP_SPACING * i}
                className={classWithModifier("line-map__stop-label", modifier)}
              >
                <tspan
                  x={LEFT_MARGIN + LINE_WIDTH + TEXT_LEFT_MARGIN}
                  dy="-1.2em"
                >
                  {labelParts[0]}
                </tspan>
                <tspan
                  x={LEFT_MARGIN + LINE_WIDTH + TEXT_LEFT_MARGIN}
                  y={TEXT_TOP_MARGIN + TOP_MARGIN + STOP_SPACING * i}
                >
                  {labelParts[1]}
                </tspan>
              </text>
            );
          } else {
            stopLabel = (
              <text
                x={LEFT_MARGIN + LINE_WIDTH + TEXT_LEFT_MARGIN}
                y={TEXT_TOP_MARGIN + TOP_MARGIN + STOP_SPACING * i}
                className={classWithModifier("line-map__stop-label", modifier)}
              >
                {labelText}
              </text>
            );
          }
        }

        return (
          <React.Fragment key={i}>
            {stopIcon}
            {stopLabel}
          </React.Fragment>
        );
      })}
    </>
  );
};

const BaseMap = ({ stops }) => {
  return (
    <>
      <BaseMapFuture stops={stops} />
      <BaseMapPast stops={stops} />
      <BaseMapCurrent stops={stops} />
      <BaseMapStops stops={stops} />
    </>
  );
};

const ScheduledDepartureIcon = ({ cx, cy }) => {
  return (
    <>
      <circle
        cx={cx}
        cy={cy}
        r={BIG_STOP_RADIUS}
        className="line-map__scheduled-departure"
      />
      <VehicleIcon cx={cx} cy={cy} iconSize={VEHICLE_ICON_SIZE} />
    </>
  );
};

const ScheduledDepartureDescription = ({ cx, cy, timestamp, stationName }) => {
  const x = cx + LINE_WIDTH / 2 + TEXT_LEFT_MARGIN;
  const y = cy + BIG_STOP_RADIUS / 2;

  return (
    <text x={x} y={y}>
      <tspan
        className={classWithModifier("line-map__scheduled-departure", "time")}
      >
        {timestamp}
      </tspan>
      <tspan
        x={x}
        dy="36"
        className={classWithModifier(
          "line-map__scheduled-departure",
          "message"
        )}
      >
        Scheduled to depart
      </tspan>
      <tspan
        x={x}
        dy="32"
        className={classWithModifier(
          "line-map__scheduled-departure",
          "message"
        )}
      >
        {stationName}
      </tspan>
    </text>
  );
};

const ScheduledDeparture = ({
  numStops,
  timestamp,
  station_name: stationName,
}) => {
  const cx = LEFT_MARGIN + LINE_WIDTH / 2;
  const cy = TOP_MARGIN + STOP_SPACING * numStops;

  return (
    <>
      <ScheduledDepartureIcon cx={cx} cy={cy} />
      <ScheduledDepartureDescription
        cx={cx}
        cy={cy}
        timestamp={timestamp}
        stationName={stationName}
      />
    </>
  );
};

const degreesToRadians = (angleInDegrees) => {
  return (angleInDegrees * Math.PI) / 180.0;
};

const VehicleDroplet = ({ cx, cy }) => {
  // Parameters
  const radius = BIG_STOP_RADIUS;
  const directionAngle = 45;

  // Compute points
  const centerAngle = 270;
  const startAngle = degreesToRadians(centerAngle - directionAngle);
  const endAngle = degreesToRadians(centerAngle + directionAngle);
  const startX = cx + radius * Math.cos(startAngle);
  const startY = cy + radius * Math.sin(startAngle);
  const endX = cx + radius * Math.cos(endAngle);
  const endY = cy + radius * Math.sin(endAngle);
  const pointX = cx;
  const pointY = cy - radius / Math.cos((startAngle - endAngle) / 2);

  // Path data
  const d = [
    "M",
    startX,
    startY,
    "A",
    radius,
    radius,
    0,
    1,
    0,
    endX,
    endY,
    "L",
    pointX,
    pointY,
    "Z",
  ].join(" ");

  return <path d={d} className="line-map__vehicle-droplet" />;
};

const VehicleIcon = ({ cx, cy, iconSize }) => {
  const viewBoxSize = 128; // property of the path
  const scale = iconSize / viewBoxSize;

  return (
    <g
      transform={
        "translate(" +
        (cx - iconSize / 2) +
        ", " +
        (cy - iconSize / 2) +
        ") scale(" +
        scale +
        ")"
      }
    >
      <path
        d="M44.8825019,13.9985834 L45.200153,14.0009999 L83.117284,14.0000017 C91.2380941,14.0585408 97.8713422,20.576518 98.0335851,28.7341526 L98.0335851,28.7341526 L98.0335851,83.1671083 C97.9844822,90.1165254 93.1479625,96.113536 86.3665559,97.6335637 L86.3665559,97.6335637 L104,124 L94.000075,124 L81.4333436,105.566684 L46.7667569,105.566684 L34.2000255,124 L24,124 L41.5668439,97.6335637 C34.7855565,96.1134158 29.9491856,90.1164357 29.9001148,83.1671083 L29.9001148,83.1671083 L29.9001148,28.700853 C30.082492,20.4239828 36.9225061,13.8522867 45.200153,14.0009999 Z M47.3176012,76.8409304 C44.8263083,75.8090489 41.9587251,76.3794898 40.0520239,78.286253 C38.1453227,80.1930162 37.5750036,83.0605893 38.6070102,85.5518045 C39.6390167,88.0430198 42.0701085,89.6671433 44.7666519,89.6671433 C48.4485712,89.6669776 51.4332686,86.6821832 51.4332686,83.00031 C51.4332686,80.3038003 49.808894,77.872812 47.3176012,76.8409304 Z M82.9667974,76.2669608 C79.2728998,76.2669608 76.2758223,79.2565289 76.2665802,82.9503689 C76.2573808,86.6442089 79.2394957,89.6487022 82.9333473,89.6671433 L82.9333473,89.6671433 L83.0002475,89.6671433 C86.6940991,89.6487022 89.676214,86.6442089 89.6670146,82.9503689 C89.6577726,79.2565289 86.6606951,76.2669608 82.9667974,76.2669608 Z M82.5928589,29.1915756 L82.3000458,29.200948 L45.6333541,29.200948 C43.580738,29.0932838 41.5792601,29.864029 40.1290268,31.3205986 C38.6787935,32.7771681 37.9167965,34.7819715 38.0334351,36.8340716 L38.0334351,36.8340716 L38.0334351,46.6340736 C37.9428296,48.5591437 38.6207068,50.4413552 39.9179302,51.8666122 C41.2151536,53.2918691 43.0254527,54.1434122 44.9505524,54.2338976 C45.1779529,54.2446975 45.4059535,54.2446975 45.6333541,54.2338976 L45.6333541,54.2338976 L82.3000458,54.2338976 C84.2251399,54.3245019 86.1073749,53.6466332 87.5326497,52.349426 C88.9579245,51.0522188 89.8094782,49.2419425 89.8999647,47.3168668 C89.9107648,47.0890691 89.9107648,46.8614714 89.8999647,46.6340736 L89.8999647,46.6340736 L89.8999647,36.8340716 C90.0162165,34.7820752 89.2540943,32.7775009 87.8039495,31.3210202 C86.3538047,29.8645396 84.3525564,29.0936702 82.3000458,29.200948 Z M71.5000188,17.2343668 L56.6334816,17.2343668 C55.2724793,17.2333028 54.1538025,18.3077224 54.0999752,19.6676433 L54.0999752,19.6676433 L54.0999752,24.0010999 C54.108748,24.6641795 54.3806231,25.2966045 54.8557695,25.7591984 C55.3309159,26.2217922 55.9703964,26.4766462 56.6334816,26.4676753 L56.6334816,26.4676753 L71.4001185,26.500975 C72.7797632,26.5560897 73.9428956,25.4824218 73.998125,24.1027989 L73.998125,24.1027989 L73.999925,24.0010999 L73.999925,19.6676433 C73.9468627,18.3205696 72.8480507,17.2510446 71.5000188,17.2343668 L71.5000188,17.2343668 Z M58.4339861,4 C60.7721541,4.00011046 62.6675862,5.89551885 62.6676966,8.23365765 C62.6678071,10.5717964 60.7725541,12.4673839 58.4343861,12.4677153 L58.4343861,12.4677153 L58.4334861,12.4677153 C57.3110185,12.4692339 56.2335871,12.0230424 55.4393587,11.2285989 C54.6451304,10.4341554 54.1992386,9.35661107 54.1998748,8.23325762 C54.2002069,5.89511884 56.095818,3.99988954 58.4339861,4 Z M69.6667142,4.00119994 C72.004707,4.00119994 73.9000248,5.89649396 73.9000248,8.23445761 C73.9000248,10.5724213 72.004707,12.4677153 69.6667142,12.4677153 C68.543946,12.4677153 67.4671407,12.0218178 66.6732237,11.2279107 C65.8793067,10.4340036 65.4334036,9.35721174 65.4334036,8.23445761 C65.4334036,5.89649396 67.3287213,4.00119994 69.6667142,4.00119994 Z"
        fill="white"
      />
    </g>
  );
};

const VehicleTextLabel = ({ cx, cy, text }) => {
  return (
    <text
      x={cx + LINE_WIDTH / 2 + TEXT_LEFT_MARGIN}
      y={cy + VEHICLE_ICON_SIZE}
      className={classWithModifier("line-map__vehicle-label", "text")}
    >
      {text}
    </text>
  );
};

const VehicleMinutesLabel = ({ cx, cy, minutes }) => {
  return (
    <text x={cx + LINE_WIDTH / 2 + TEXT_LEFT_MARGIN} y={cy + VEHICLE_ICON_SIZE}>
      <tspan
        className={classWithModifier("line-map__vehicle-label", "minutes")}
      >
        {minutes}
      </tspan>
      <tspan
        dx="3"
        className={classWithModifier(
          "line-map__vehicle-label",
          "minutes-label"
        )}
      >
        m
      </tspan>
    </text>
  );
};

const VehicleLabel = ({ cx, cy, label }) => {
  if (label.type === "text") {
    return <VehicleTextLabel cx={cx} cy={cy} text={label.text} />;
  } else if (label.type === "minutes") {
    return <VehicleMinutesLabel cx={cx} cy={cy} minutes={label.minutes} />;
  }

  return null;
};

const Vehicle = ({ id, index, label }) => {
  const cx = LEFT_MARGIN + LINE_WIDTH / 2;
  const cy = TOP_MARGIN + index * STOP_SPACING;

  return (
    <>
      <VehicleDroplet cx={cx} cy={cy} />
      <VehicleIcon cx={cx} cy={cy} iconSize={VEHICLE_ICON_SIZE} />
      {label && <VehicleLabel cx={cx} cy={cy} label={label} />}
    </>
  );
};

const Vehicles = ({ vehicles, stops }) => {
  const maxIndex = stops.length;
  vehicles = vehicles.filter(({ index }) => index <= maxIndex);

  return (
    <>
      {vehicles.map(({ id, ...data }) => (
        <Vehicle {...data} key={id} />
      ))}
    </>
  );
};

const truncateStops = (stops) => {
  const n = Math.floor(
    (HEIGHT - (TOP_MARGIN + BIG_STOP_RADIUS)) / STOP_SPACING
  );
  return stops.slice(0, n + 1);
};

const showScheduledDeparture = (stops) => {
  return (
    STOP_SPACING * (stops.length - 1) + SCHEDULED_DEPARTURE_SIZE <=
    HEIGHT - TOP_MARGIN
  );
};

const LineMap = ({
  stops,
  vehicles,
  scheduled_departure: scheduledDeparture,
}) => {
  stops = truncateStops(stops);

  return (
    <svg
      width={WIDTH + "px"}
      height={HEIGHT + "px"}
      viewBox={[0, 0, WIDTH, HEIGHT].join(" ")}
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
    >
      <BaseMap stops={stops} />
      {showScheduledDeparture(stops) && scheduledDeparture && (
        <ScheduledDeparture numStops={stops.length} {...scheduledDeparture} />
      )}
      <Vehicles vehicles={vehicles} stops={stops} />
    </svg>
  );
};

export default LineMap;
