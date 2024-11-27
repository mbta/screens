import React, { ComponentType } from "react";
import _ from "lodash";
import makePersistent, {
  WrappedComponentProps,
} from "Components/v2/persistent_wrapper";
import { type Pill } from "Components/v2/departures/route_pill";
import { Direction } from "Components/v2/arrow";
import OutsideClosuresView from "Components/v2/elevator/closures/outside_closures_view";
import CurrentElevatorClosedView, {
  type Coordinates,
} from "Components/v2/elevator/closures/current_elevator_closed_view";
import Footer from "Components/v2/elevator/footer";
import NormalHeader from "Components/v2/normal_header";

export type StationWithClosures = {
  id: string;
  name: string;
  route_icons: Pill[];
  closures: ElevatorClosure[];
};

export type ElevatorClosure = {
  id: string;
  elevator_name: string;
  elevator_id: string;
  description: string;
  header_text: string;
};

interface Props extends WrappedComponentProps {
  id: string;
  in_station_closures: ElevatorClosure[];
  other_stations_with_closures: StationWithClosures[];
  alternate_direction_text: string;
  accessible_path_direction_arrow: Direction;
  accessible_path_image_url: string | null;
  accessible_path_image_here_coordinates: Coordinates;
  time: string;
}

const ElevatorClosures: React.ComponentType<Props> = ({
  id,
  other_stations_with_closures: otherStationsWithClosures,
  in_station_closures: inStationClosures,
  alternate_direction_text: alternateDirectionText,
  accessible_path_direction_arrow: accessiblePathDirectionArrow,
  accessible_path_image_url: accessiblePathImageUrl,
  accessible_path_image_here_coordinates: accessiblePathImageHereCoordinates,
  time,
  lastUpdate,
  onFinish,
}: Props) => {
  const currentElevatorClosure = inStationClosures.find(
    (c) => c.elevator_id === id,
  );

  return (
    <>
      <NormalHeader
        text={`Elevator ${id}`}
        time={time}
        maxHeight={104}
        classModifiers={currentElevatorClosure ? "blue" : ""}
      />
      <div className="elevator-closures">
        {currentElevatorClosure ? (
          <CurrentElevatorClosedView
            closure={currentElevatorClosure}
            alternateDirectionText={alternateDirectionText}
            accessiblePathDirectionArrow={accessiblePathDirectionArrow}
            accessiblePathImageUrl={accessiblePathImageUrl}
            accessiblePathImageHereCoordinates={
              accessiblePathImageHereCoordinates
            }
            onFinish={onFinish}
            lastUpdate={lastUpdate}
          />
        ) : (
          <OutsideClosuresView
            stations={otherStationsWithClosures}
            lastUpdate={lastUpdate}
            onFinish={onFinish}
          />
        )}
      </div>
      <Footer variant={currentElevatorClosure ? "blue" : ""} />
    </>
  );
};

export default makePersistent(
  ElevatorClosures as ComponentType<WrappedComponentProps>,
);
