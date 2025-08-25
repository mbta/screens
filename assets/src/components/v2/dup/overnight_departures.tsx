import type { ComponentType } from "react";
import { classWithModifier, imagePath } from "Util/utils";
import RoutePill, { Pill } from "Components/v2/departures/route_pill";

interface Props {
  routes: Pill[];
}

const OvernightDepartures: ComponentType<Props> = ({ routes }) => {
  const getImage = () =>
    routes.length ? (
      <img
        className={classWithModifier("overnight-departures__image", "partial")}
        src={imagePath(`dup_overnight_partial.png`)}
      />
    ) : (
      <img
        className={classWithModifier("overnight-departures__image", "full")}
        src={imagePath(`dup_overnight_full.png`)}
      />
    );

  return (
    <div className="overnight-departures__container">
      {getImage()}
      <div className="overnight-departures__text-container">
        {routes.length > 0 && (
          <div className="overnight-departures__route-pill-container">
            {routes.map((route) => (
              <RoutePill pill={route} key={route.color} />
            ))}
          </div>
        )}
        <div className="overnight-departures__text">
          Service resumes in the morning
        </div>
      </div>
    </div>
  );
};

export default OvernightDepartures;
