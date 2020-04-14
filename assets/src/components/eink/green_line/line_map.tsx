import moment from "moment";
import "moment-timezone";
import React from "react";

import { timeRepresentation } from "Components/eink/base_departure_time";

const LineMapLine = ({
  data,
  height,
  width,
  currentTimeString
}): JSX.Element => {
  const radius = 14;
  const dy = 112;
  const lineWidth = 40;
  const marginLeft = 84;
  const marginTop = 32;
  const stopMarginTop = 110;
  const textMargin = 18;
  const strokeWidth = 16;

  const lastStopIndex = 2 + data.stops.count_before;
  const currentStopY = stopMarginTop + 2 * dy + radius;
  let lastStopY = stopMarginTop + lastStopIndex * dy + radius;

  const showOriginStop = lastStopY + radius + strokeWidth <= height;
  if (!showOriginStop) {
    lastStopY = height;
  }

  const showScheduledDeparture =
    data.schedule !== null && lastStopY + 8 * radius + strokeWidth <= height;

  const vehicles = data.vehicles;

  const dPast = [
    "M",
    marginLeft,
    currentStopY,
    "L",
    marginLeft + lineWidth,
    currentStopY,
    "L",
    marginLeft + lineWidth,
    lastStopY,
    "L",
    marginLeft,
    lastStopY,
    "Z"
  ].join(" ");

  const dFuture = [
    "M",
    marginLeft + lineWidth / 2,
    marginTop,
    "L",
    marginLeft + lineWidth,
    marginTop + lineWidth / 2,
    "L",
    marginLeft + lineWidth,
    currentStopY,
    "L",
    marginLeft,
    currentStopY,
    "L",
    marginLeft,
    marginTop + lineWidth / 2,
    "Z"
  ].join(" ");

  const currentStopName = data.stops.current;
  const nextStopName = data.stops.next;
  const followingStopName = data.stops.following;
  const originStopName = data.stops.origin;

  return (
    <g>
      <path d={dPast} fill="#CCCCCC"></path>
      <path d={dFuture} fill="#000000"></path>
      {[...Array(lastStopIndex)].map((_, i) =>
        stopMarginTop + radius + i * dy < height ? (
          <circle
            cx={marginLeft + lineWidth / 2}
            cy={stopMarginTop + radius + i * dy}
            r={radius}
            fill="#FFFFFF"
            stroke="none"
            key={"circle-" + i}
          ></circle>
        ) : null
      )}
      <circle
        cx={marginLeft + lineWidth / 2}
        cy={currentStopY}
        r={radius + strokeWidth / 2}
        fill="#FFFFFF"
        stroke="#000000"
        strokeWidth={strokeWidth}
      ></circle>
      {showOriginStop ? (
        <circle
          cx={marginLeft + lineWidth / 2}
          cy={lastStopY}
          r={radius + strokeWidth / 2}
          fill="#FFFFFF"
          stroke="#CCCCCC"
          strokeWidth={strokeWidth}
        ></circle>
      ) : null}
      {showScheduledDeparture ? (
        <ScheduledDeparture
          lastStopX={marginLeft + lineWidth / 2}
          lastStopY={lastStopY}
          stopRadius={radius}
          stopName={originStopName}
          time={data.schedule.time}
        />
      ) : null}

      {/* Stop labels */}
      <LineMapStopLabel
        x={marginLeft + lineWidth + textMargin}
        y={stopMarginTop + 2 * radius}
        lines={[followingStopName]}
      />
      <LineMapStopLabel
        x={marginLeft + lineWidth + textMargin}
        y={stopMarginTop + 2 * radius + dy}
        lines={[nextStopName]}
      />
      <LineMapStopLabel
        x={marginLeft + lineWidth + textMargin}
        y={stopMarginTop + 2 * radius + 2 * dy}
        lines={[currentStopName]}
        current={true}
      />
      {showOriginStop ? (
        <LineMapStopLabel
          x={marginLeft + lineWidth + textMargin}
          y={stopMarginTop + 2 * radius + lastStopIndex * dy}
          lines={[originStopName]}
          origin={true}
        />
      ) : null}
      {vehicles.map(v => (
        <LineMapVehicle
          x={marginLeft + lineWidth / 2}
          y={stopMarginTop + radius + v.index * dy}
          height={height}
          time={v.index >= 2 ? v.time : null}
          currentTimeString={currentTimeString}
          key={v.id}
        />
      ))}
    </g>
  );
};

const ScheduledDeparture = ({
  lastStopX,
  lastStopY,
  stopRadius,
  stopName,
  time
}): JSX.Element => {
  const x = lastStopX;
  const y = lastStopY + stopRadius * 7;
  const radius = 30;
  const margin = 9;

  return (
    <g>
      <circle cx={x} cy={y} r={radius} fill="#999999" strokeWidth="0"></circle>
      <LineMapVehicleIcon
        x={x - radius * 0.8}
        y={y - radius * 0.8}
        size={radius * 1.6}
      />
      <text
        x={x + radius + margin}
        y={y + 12}
        fontFamily="neue-haas-grotesk-text"
        fill="#999999"
      >
        <tspan fontSize="40" fontWeight="700">
          {moment(time)
            .tz("America/New_York")
            .format("h:mm")}
        </tspan>
        <tspan fontSize="24" dy="36" x={x + radius + margin}>
          Scheduled to depart
        </tspan>
        <tspan fontSize="24" dy="32" x={x + radius + margin}>
          {stopName}
        </tspan>
      </text>
    </g>
  );
};

const LineMapStopLabel = ({ x, y, lines, current, origin }): JSX.Element => {
  const fontSize = 24;
  const lineHeight = 32;
  const fontFamily = "neue-haas-grotesk-text";
  const fontWeight = current ? 700 : 400;
  const fontColor = origin ? "#999999" : "#000000";

  if (lines.length === 1) {
    return (
      <text
        x={x}
        y={y - 5} // fudged so that centers align
        fontFamily={fontFamily}
        fontSize={fontSize}
        fontWeight={fontWeight}
        fill={fontColor}
      >
        {lines[0]}
      </text>
    );
  } else if (lines.length === 2) {
    return (
      <text
        x={x}
        y={y - 5 - lineHeight} // fudged so that centers align
        fontFamily={fontFamily}
        fontSize={fontSize}
        fontWeight={fontWeight}
        fill={fontColor}
      >
        <tspan>{lines[0]}</tspan>
        <tspan x={x} dy={lineHeight}>
          {lines[1]}
        </tspan>
      </text>
    );
  }
};

// Helper function
const degreesToRadians = angleInDegrees => {
  return (angleInDegrees * Math.PI) / 180.0;
};

const LineMapVehicle = ({
  x,
  y,
  height,
  time,
  currentTimeString
}): JSX.Element => {
  if (y > height) {
    return null;
  }

  // Parameters
  const centerX = x;
  const centerY = y;
  const radius = 30;
  const directionAngle = 45;
  const iconSize = 44;

  // Compute points
  const centerAngle = 270;
  const startAngle = degreesToRadians(centerAngle - directionAngle);
  const endAngle = degreesToRadians(centerAngle + directionAngle);
  const startX = centerX + radius * Math.cos(startAngle);
  const startY = centerY + radius * Math.sin(startAngle);
  const endX = centerX + radius * Math.cos(endAngle);
  const endY = centerY + radius * Math.sin(endAngle);
  const pointX = centerX;
  const pointY = centerY - radius / Math.cos((startAngle - endAngle) / 2);

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
    "Z"
  ].join(" ");

  // Format time
  let timeLabel = null;

  if (time !== null) {
    const timeRep = timeRepresentation(time, currentTimeString);
    if (timeRep.type === "TIME_NOW") {
      timeLabel = (
        <text
          x={x + 20 + 18} // lineWidth / 2 + textMargin
          y={y + 44} // eyeballed it...
          fontFamily="neue-haas-grotesk-text"
          fontSize="40"
          fontWeight="700"
          textAnchor="right"
        >
          Now
        </text>
      );
    } else if (timeRep.type === "TIME_MINUTES") {
      timeLabel = (
        <text
          x={x + 20 + 18} // lineWidth / 2 + textMargin
          y={y + 44} // eyeballed it...
          fontFamily="neue-haas-grotesk-text"
        >
          <tspan fontSize="40" fontWeight="700" textAnchor="right">
            {timeRep.minutes}
          </tspan>
          <tspan fontSize="30" fontWeight="400" textAnchor="right" dx="3">
            m
          </tspan>
        </text>
      );
    }
  }

  return (
    <g>
      <path
        d={d}
        fill="#000000"
        stroke="#FFFFFF"
        strokeWidth="8"
        strokeLinejoin="round"
      ></path>
      <LineMapVehicleIcon
        x={centerX - iconSize / 2}
        y={centerY - iconSize / 2}
        size={iconSize}
      />
      {timeLabel}
    </g>
  );
};

const LineMapVehicleIcon = ({ x, y, size }): JSX.Element => {
  const viewBoxSize = 128; // property of the path
  const scale = size / viewBoxSize;
  return (
    <g transform={"translate(" + x + ", " + y + ") scale(" + scale + ")"}>
      <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
        <path
          d="M44.8825019,13.9985834 L45.200153,14.0009999 L83.117284,14.0000017 C91.2380941,14.0585408 97.8713422,20.576518 98.0335851,28.7341526 L98.0335851,28.7341526 L98.0335851,83.1671083 C97.9844822,90.1165254 93.1479625,96.113536 86.3665559,97.6335637 L86.3665559,97.6335637 L104,124 L94.000075,124 L81.4333436,105.566684 L46.7667569,105.566684 L34.2000255,124 L24,124 L41.5668439,97.6335637 C34.7855565,96.1134158 29.9491856,90.1164357 29.9001148,83.1671083 L29.9001148,83.1671083 L29.9001148,28.700853 C30.082492,20.4239828 36.9225061,13.8522867 45.200153,14.0009999 Z M47.3176012,76.8409304 C44.8263083,75.8090489 41.9587251,76.3794898 40.0520239,78.286253 C38.1453227,80.1930162 37.5750036,83.0605893 38.6070102,85.5518045 C39.6390167,88.0430198 42.0701085,89.6671433 44.7666519,89.6671433 C48.4485712,89.6669776 51.4332686,86.6821832 51.4332686,83.00031 C51.4332686,80.3038003 49.808894,77.872812 47.3176012,76.8409304 Z M82.9667974,76.2669608 C79.2728998,76.2669608 76.2758223,79.2565289 76.2665802,82.9503689 C76.2573808,86.6442089 79.2394957,89.6487022 82.9333473,89.6671433 L82.9333473,89.6671433 L83.0002475,89.6671433 C86.6940991,89.6487022 89.676214,86.6442089 89.6670146,82.9503689 C89.6577726,79.2565289 86.6606951,76.2669608 82.9667974,76.2669608 Z M82.5928589,29.1915756 L82.3000458,29.200948 L45.6333541,29.200948 C43.580738,29.0932838 41.5792601,29.864029 40.1290268,31.3205986 C38.6787935,32.7771681 37.9167965,34.7819715 38.0334351,36.8340716 L38.0334351,36.8340716 L38.0334351,46.6340736 C37.9428296,48.5591437 38.6207068,50.4413552 39.9179302,51.8666122 C41.2151536,53.2918691 43.0254527,54.1434122 44.9505524,54.2338976 C45.1779529,54.2446975 45.4059535,54.2446975 45.6333541,54.2338976 L45.6333541,54.2338976 L82.3000458,54.2338976 C84.2251399,54.3245019 86.1073749,53.6466332 87.5326497,52.349426 C88.9579245,51.0522188 89.8094782,49.2419425 89.8999647,47.3168668 C89.9107648,47.0890691 89.9107648,46.8614714 89.8999647,46.6340736 L89.8999647,46.6340736 L89.8999647,36.8340716 C90.0162165,34.7820752 89.2540943,32.7775009 87.8039495,31.3210202 C86.3538047,29.8645396 84.3525564,29.0936702 82.3000458,29.200948 Z M71.5000188,17.2343668 L56.6334816,17.2343668 C55.2724793,17.2333028 54.1538025,18.3077224 54.0999752,19.6676433 L54.0999752,19.6676433 L54.0999752,24.0010999 C54.108748,24.6641795 54.3806231,25.2966045 54.8557695,25.7591984 C55.3309159,26.2217922 55.9703964,26.4766462 56.6334816,26.4676753 L56.6334816,26.4676753 L71.4001185,26.500975 C72.7797632,26.5560897 73.9428956,25.4824218 73.998125,24.1027989 L73.998125,24.1027989 L73.999925,24.0010999 L73.999925,19.6676433 C73.9468627,18.3205696 72.8480507,17.2510446 71.5000188,17.2343668 L71.5000188,17.2343668 Z M58.4339861,4 C60.7721541,4.00011046 62.6675862,5.89551885 62.6676966,8.23365765 C62.6678071,10.5717964 60.7725541,12.4673839 58.4343861,12.4677153 L58.4343861,12.4677153 L58.4334861,12.4677153 C57.3110185,12.4692339 56.2335871,12.0230424 55.4393587,11.2285989 C54.6451304,10.4341554 54.1992386,9.35661107 54.1998748,8.23325762 C54.2002069,5.89511884 56.095818,3.99988954 58.4339861,4 Z M69.6667142,4.00119994 C72.004707,4.00119994 73.9000248,5.89649396 73.9000248,8.23445761 C73.9000248,10.5724213 72.004707,12.4677153 69.6667142,12.4677153 C68.543946,12.4677153 67.4671407,12.0218178 66.6732237,11.2279107 C65.8793067,10.4340036 65.4334036,9.35721174 65.4334036,8.23445761 C65.4334036,5.89649396 67.3287213,4.00119994 69.6667142,4.00119994 Z"
          fill="#FFFFFF"
        ></path>
      </g>
    </g>
  );
};

const LineMap = ({ data, height, currentTimeString }): JSX.Element => {
  if (!data) {
    return <div className="line-map"></div>;
  }

  // We set the SVG height to fill the entire screen due to an issue on Mercury double-stack signs.
  const screenHeight = height === 1140 ? 1140 : 2740;

  const width = 442;
  return (
    <div className="line-map">
      <svg
        width={width + "px"}
        height={screenHeight + "px"}
        viewBox={[0, 0, width, screenHeight].join(" ")}
        version="1.1"
        xmlns="http://www.w3.org/2000/svg"
        className="line-map__svg"
      >
        <LineMapLine
          data={data}
          height={height}
          width={width}
          currentTimeString={currentTimeString}
        />
      </svg>
    </div>
  );
};

export default LineMap;
