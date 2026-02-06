import type { ComponentType } from "react";
import { imagePath } from "Util/utils";
import LinkArrow from "../bundled_svg/link_arrow";

const DeparturesNoService: ComponentType = () => {
  return (
    <div className="no-service__container">
      <div className="no-service__body">
        <div className="no-service__icon-container">
          <img className="no-service__icon-image" src={imagePath("info.svg")} />
        </div>
        <div className="no-service__message">No Service today</div>
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
