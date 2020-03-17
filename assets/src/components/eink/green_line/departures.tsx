import moment from "moment";
import "moment-timezone";
import React from "react";

import InlineAlert from "Components/eink/green_line/inline_alert";

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

const HeadwayMessage = ({ destination, headway }): JSX.Element => {
  const range = 2;
  return (
    <div className="departures__headway-message">
      Trains to {destination} every {headway - range}-{headway + range} minutes
    </div>
  );
};

const Departures = ({
  departures,
  destination,
  headway,
  inlineAlert,
  currentTimeString
}): JSX.Element => {
  departures = departures.slice(0, 2);

  const topDeparture = departures[0];
  const bottomDeparture = departures[1];

  return (
    <div className="departures">
      <div className="departures__container">
        {topDeparture ? (
          <Departure
            time={topDeparture.time}
            currentTimeString={currentTimeString}
          />
        ) : (
          <HeadwayMessage destination={destination} headway={headway} />
        )}
        <div className="departures__hairline"></div>
        {bottomDeparture ? (
          <Departure
            time={bottomDeparture.time}
            currentTimeString={currentTimeString}
          />
        ) : topDeparture ? (
          <HeadwayMessage destination={destination} headway={headway} />
        ) : null}
        <div className="departures__delay-badge">
          <InlineAlert alertData={inlineAlert} />
        </div>
      </div>
    </div>
  );
};

export default Departures;
