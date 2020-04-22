import React from "react";

import BaseDepartureTime from "Components/eink/base_departure_time";
import InlineAlert from "Components/eink/green_line/inline_alert";
import TakeoverInlineAlert from "Components/eink/green_line/takeover_inline_alert";

const Departure = ({ time, currentTimeString }): JSX.Element => {
  return (
    <div className="departures__departure">
      <BaseDepartureTime
        departureTimeString={time}
        currentTimeString={currentTimeString}
      />
    </div>
  );
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
  currentTimeString,
  serviceLevel,
}): JSX.Element => {
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
          {serviceLevel > 1 ? (
            <TakeoverInlineAlert />
          ) : (
            <InlineAlert alertData={inlineAlert} />
          )}
        </div>
      </div>
    </div>
  );
};

export default Departures;
