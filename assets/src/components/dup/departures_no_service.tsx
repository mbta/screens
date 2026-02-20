import type { ComponentType } from "react";
import { imagePath } from "Util/utils";
import LinkArrow from "../bundled_svg/link_arrow";
import RoutePill, { Pill } from "Components/departures/route_pill";

interface DeparturesNoService {
  routes: Pill[];
}

const DeparturesNoService: ComponentType<DeparturesNoService> = ({
  routes,
}) => {
  const hasRoutes = routes.length > 0;

  return (
    <div className="no-service__container">
      <div className="no-service__top-section">
        <div
          className={`no-service__body ${
            hasRoutes
              ? "no-service__body--with-routes"
              : "no-service__body--no-routes"
          }`}
        >
          <div className="no-service__top-row">
            <img
              className="no-service__icon-image"
              src={imagePath("info.svg")}
            />

            {hasRoutes && (
              <div className="no-service__route-pill-container">
                {routes.map((route) => (
                  <RoutePill pill={route} key={route.color} />
                ))}
              </div>
            )}
          </div>

          <div className="no-service__message">No service today</div>
        </div>
      </div>

      <div className="no-service__link">
        <div className="no-service__link-arrow">
          <LinkArrow width={375} colorHex="#a2a3a3" />
        </div>
        <div className="no-service__link-text">mbta.com/schedules</div>
      </div>
    </div>
  );
};

export default DeparturesNoService;
