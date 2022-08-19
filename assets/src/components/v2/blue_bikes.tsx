import React, { ComponentType } from "react";
import Arrow, { Direction } from "Components/solari/arrow";
import ClockIcon from "Components/v2/clock_icon";
import { imagePath } from "Util/util";

interface Props {
  destination: string;
  minutes_range_to_destination: `${number}-${number}`;
  stations: Station[];
}

type Station = NormalStation | ValetStation | OutOfServiceStation;

type NormalStation = BaseStation & {
  status: "normal";
  num_bikes_available: string;
  num_docks_available: string;
};

type ValetStation = BaseStation & {
  status: "valet";
};

type OutOfServiceStation = BaseStation & {
  status: "out_of_service";
};

interface BaseStation {
  id: string;
  arrow: Direction;
  walk_distance_minutes: number;
  walk_distance_feet: number;
  name: string;
}

const BlueBikes: ComponentType<Props> = (props) => {
  return (
    <div className="blue-bikes">
      <div className="blue-bikes__card">
        <Header />
        <Stations stations={props.stations} />
        <Footer
          destination={props.destination}
          minutesRangeToDestination={props.minutes_range_to_destination}
        />
      </div>
    </div>
  );
};

const Header: ComponentType<{}> = () => {
  return (
    <div className="blue-bikes__header">
      <div className="blue-bikes__header__bike-icon-container">
        <img
          className="blue-bikes__header__bike-icon"
          src={imagePath("bike.svg")}
        />
      </div>
      <div className="blue-bikes__header__wordmark-icon-container">
        <img
          className="blue-bikes__header__wordmark-icon"
          src={imagePath("blue-bikes-wordmark.svg")}
        />
      </div>
      <div className="blue-bikes__header__qr-container">
        <img
          className="blue-bikes__header__qr"
          src={imagePath("blue-bikes-surge-qr-code.png")}
        />
      </div>
    </div>
  );
};

interface StationsProps {
  stations: Station[];
}

const Stations: ComponentType<StationsProps> = ({ stations }) => {
  return (
    <div className="blue-bikes__stations">
      <div className="blue-bikes__stations-header">
        <div className="blue-bikes__stations-header__distance">
          <div className="blue-bikes__stations-header__main-text">
            Walking distance
          </div>
          <div className="blue-bikes__stations-header__alt-text">
            Distancia peatonal
          </div>
        </div>
        <div className="blue-bikes__stations-header__bikes">
          <div className="blue-bikes__stations-header__main-text">Bikes</div>
          <div className="blue-bikes__stations-header__alt-text">
            Bicicletas
          </div>
        </div>
        <div className="blue-bikes__stations-header__docks">
          <div className="blue-bikes__stations-header__main-text">Docks</div>
          <div className="blue-bikes__stations-header__alt-text">Puestos</div>
        </div>
      </div>
      {stations.map((station) => (
        <StationRow key={station.id} {...station} />
      ))}
    </div>
  );
};

const StationRow: ComponentType<Station> = (station) => {
  let row;
  switch (station.status) {
    case "normal":
      row = <NormalRow {...station} />;
      break;
    case "valet":
      row = <ValetRow {...station} />;
      break;
    case "out_of_service":
      row = <OutOfServiceRow {...station} />;
      break;
  }

  return (
    <>
      <div className="blue-bikes__station-hairline" />
      {row}
    </>
  );
};

const NormalRow: ComponentType<NormalStation> = (station) => {
  return (
    <div className="blue-bikes__station">
      <Arrow
        direction={station.arrow}
        className="blue-bikes__station__arrow-image"
      />
      <Distance
        walkDistanceMinutes={station.walk_distance_minutes}
        walkDistanceFeet={station.walk_distance_feet}
      />
      <div className="blue-bikes__station__bikes">{station.num_bikes_available}</div>
      <div className="blue-bikes__station__docks">{station.num_docks_available}</div>
    </div>
  );
};

const ValetRow: ComponentType<ValetStation> = (station) => {
  return (
    <div className="blue-bikes__station">
      <Arrow
        direction={station.arrow}
        className="blue-bikes__station__arrow-image"
      />
      <Distance
        walkDistanceMinutes={station.walk_distance_minutes}
        walkDistanceFeet={station.walk_distance_feet}
      />
      <div className="blue-bikes__station__valet-main-text">
        Unlimited
      </div>
      <div className="blue-bikes__station__valet-alt-text">
        ilimitado
      </div>
    </div>
  );
};

const OutOfServiceRow: ComponentType<OutOfServiceStation> = (station) => {
  return (
    <div className="blue-bikes__station">
      <Arrow
        direction={station.arrow}
        className="blue-bikes__station__arrow-image blue-bikes--out-of-service"
      />
      <Distance
        walkDistanceMinutes={station.walk_distance_minutes}
        walkDistanceFeet={station.walk_distance_feet}
        isOutOfService
      />
      <div className="blue-bikes__station__out-of-service">
        <div className="blue-bikes__station__out-of-service-main-text">
          Out of service
        </div>
        <div className="blue-bikes__station__out-of-service-alt-text">
          Fuera de servicio
        </div>
      </div>
    </div>
  );
};

interface DistanceProps {
  walkDistanceMinutes: number;
  walkDistanceFeet: number;
  isOutOfService?: boolean;
}

const Distance: ComponentType<DistanceProps> = ({
  walkDistanceMinutes,
  walkDistanceFeet,
  isOutOfService = false,
}) => {
  const mod = isOutOfService
    ? (className: string) => `${className} blue-bikes--out-of-service`
    : (className: string) => className;

  return (
    <div className="blue-bikes__distance">
      <div className={mod("blue-bikes__distance-minutes-value")}>
        {walkDistanceMinutes}
      </div>
      <div className={mod("blue-bikes__distance-minutes-unit")}> min</div>
      <div className={mod("blue-bikes__distance-feet")}>
        {walkDistanceFeet} ft
      </div>
    </div>
  );
};

interface FooterProps {
  destination: string;
  minutesRangeToDestination: string;
}

const Footer: ComponentType<FooterProps> = (props) => {
  let maxMinutes = parseInt(props.minutesRangeToDestination.split("-")[1]);
  if (isNaN(maxMinutes)) {
    maxMinutes = 15;
  }

  return (
    <div className="blue-bikes__footer">
      <div className="blue-bikes__footer__clock-icon-container">
        <ClockIcon minutes={maxMinutes} fgColor="rgb(23, 31, 38)" bgColor="transparent" />
      </div>
      <div className="blue-bikes__footer__distance-to-destination">
        <div className="blue-bikes__footer__main-text">
          {props.minutesRangeToDestination}m to {props.destination}
        </div>
        <div className="blue-bikes__footer__alt-text">
          paseo a {props.destination}
        </div>
      </div>
      <div className="blue-bikes__footer__free-icon-container">
        <img className="blue-bikes__footer__free-icon" src={imagePath("free-green.svg")} />
      </div>
      <div className="blue-bikes__footer__passes">
        <div className="blue-bikes__footer__main-text">
          Free passes
        </div>
        <div className="blue-bikes__footer__alt-text">
          pases gratis
        </div>
      </div>
    </div>
  );
};

export default BlueBikes;
