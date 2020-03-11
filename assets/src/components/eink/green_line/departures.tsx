import moment from "moment";
import "moment-timezone";
import React from "react";

const Departure = ({ time, currentTimeString }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (secondDifference < 60) {
    return (
      <div className="departures__departure">
        <span className="departures__departure--now">Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className="departures__departure">
        <span className="departures__departure--minutes">
          {minuteDifference}
        </span>
        <span className="departures__departure--minutes-label">m</span>
      </div>
    );
  } else {
    const timestamp = departureTime.tz("America/New_York").format("h:mm");
    const ampm = departureTime.tz("America/New_York").format("A");
    return (
      <div className="departures__departure">
        <span className="departures__departure--timestamp">{timestamp}</span>
        <span className="departures__departure--ampm">{ampm}</span>
      </div>
    );
  }
};

const Departures = ({ departures, currentTimeString }): JSX.Element => {
  departures = departures.slice(0, 2);

  const topDeparture = departures[0];
  const bottomDeparture = departures[1];

  return (
    <div className="departures">
      <Departure
        time={topDeparture.time}
        currentTimeString={currentTimeString}
      />
      <div className="departures__hairline"></div>
      <Departure
        time={bottomDeparture.time}
        currentTimeString={currentTimeString}
      />
    </div>
  );
};

export default Departures;
