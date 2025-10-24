import { type ComponentType } from "react";

import NormalServiceIcon from "Images/normal-service.svg";

const className = (elementName: string | null = null) =>
  `elevator-status-new${elementName ? `__${elementName}` : ""}`;

type AllOk = { with_backups: boolean };
type AllOkWithAlternatives = { count: number };
type ClosedElsewhere = {
  station_names: string[];
  other_closures_count: number;
  other_closures_without_alternatives_count: number;
};
type ClosedHere = {
  elevator_names: string[];
  station_id: string;
  summary?: string;
};

type Props =
  | ({ layout: "all_ok" } & AllOk)
  | ({ layout: "all_ok_with_alternatives" } & AllOkWithAlternatives)
  | ({ layout: "closed_elsewhere" } & ClosedElsewhere)
  | ({ layout: "closed_here" } & ClosedHere);

const AllOk: ComponentType<AllOk> = ({ with_backups }) => (
  <>
    <WidgetTitle />
    <NormalService />
    <h3>All MBTA elevators are working{!with_backups && "."}</h3>
    {with_backups && <p className="b4">or have a backup within 20 feet.</p>}

    <div className={className("cta")}>
      <div>(icon)</div>
      <div>
        <p className="b3">
          Live elevator alerts on <b>MBTA Go</b>
        </p>
        <p className="b2">
          <b>mbta.com/go-access</b>
        </p>
      </div>
      <div>(QR code)</div>
    </div>
  </>
);

const AllOkWithAlternatives: ComponentType<AllOkWithAlternatives> = ({
  count,
}) => (
  <>
    <WidgetTitle />
    <NormalService />
    <h4>All elevators at this station are working.</h4>
    <ElsewhereSummary total={count} withoutAlternatives={0} />
  </>
);

const ClosedElsewhere: ComponentType<ClosedElsewhere> = ({
  station_names,
  other_closures_count,
  other_closures_without_alternatives_count,
}) => (
  <>
    <div>(alert icon)</div>

    {station_names.length == 1 ? (
      <h4>Elevator closed at {station_names[0]}</h4>
    ) : (
      <>
        <h4>Elevators closed at:</h4>
        <ul className="b4">
          {station_names.map((name) => (
            <li key={name}>{name}</li>
          ))}
        </ul>
      </>
    )}

    <ElsewhereSummary
      total={other_closures_count}
      withoutAlternatives={other_closures_without_alternatives_count}
    />
  </>
);

const ClosedHere: ComponentType<ClosedHere> = ({
  elevator_names,
  station_id,
  summary,
}) => (
  <>
    <div>(alert icon)</div>

    <h4>
      {elevator_names.length > 1 ? "Elevators are" : "An elevator is"} closed at
      this station.
    </h4>

    {elevator_names.length > 1 ? (
      <ul className="b4">
        {elevator_names.map((name) => (
          <li key={name}>{name}</li>
        ))}
      </ul>
    ) : (
      <p className="b4">
        {elevator_names[0]} is unavailable. {summary}
      </p>
    )}

    <p className="b4">
      For more info, go to <b>mbta.com/stops/{station_id}</b>.
    </p>
  </>
);

const ElsewhereSummary: ComponentType<{
  total: number;
  withoutAlternatives: number;
}> = ({ total, withoutAlternatives }) => (
  <>
    <p className="b4">
      {summaryCounts(total, withoutAlternatives)} Check your trip at{" "}
      <b>mbta.com/elevators</b>.
    </p>
    <div>(QR code)</div>
  </>
);

const summaryCounts = (total, withoutAlts) => {
  switch (true) {
    case withoutAlts > 0 && total == withoutAlts:
      return (
        <>
          +{total} other MBTA elevator{total > 1 ? "s are" : " is"} closed,{" "}
          <b>
            which {total > 1 ? "have" : "has"} no in-station alternative path
            {total > 1 && "s"}
          </b>
          .
        </>
      );
    case withoutAlts > 0:
      return (
        <>
          +{total} other MBTA elevator{total > 1 ? "s are" : " is"} closed,{" "}
          <b>
            including {withoutAlts} without {withoutAlts == 1 && "an "}
            in-station alternative path
            {withoutAlts > 1 && "s"}
          </b>
          .
        </>
      );
    case total > 1:
      return (
        <>
          <b>+{total} other MBTA elevators are closed</b> (which have in-station
          alternative paths).
        </>
      );
    case total == 1:
      return (
        <>
          <b>+1 other MBTA elevator is closed</b> (which has an in-station
          alternative path).
        </>
      );
    default:
      // both total and withoutAlts are 0
      return null;
  }
};

const WidgetTitle: ComponentType = () => (
  <div className={className("title")}>Elevator Status</div>
);

const NormalService: ComponentType = () => (
  <NormalServiceIcon width={160} height={160} fill="#00803b" />
);

const ElevatorStatus: ComponentType<Props> = (props) => (
  <div className={className()}>{renderLayout(props)}</div>
);

const renderLayout = (props: Props) => {
  switch (props.layout) {
    case "all_ok":
      return <AllOk {...props} />;
    case "all_ok_with_alternatives":
      return <AllOkWithAlternatives {...props} />;
    case "closed_elsewhere":
      return <ClosedElsewhere {...props} />;
    case "closed_here":
      return <ClosedHere {...props} />;
  }
};

export default ElevatorStatus;
