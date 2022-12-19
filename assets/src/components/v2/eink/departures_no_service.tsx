import React, { ComponentType } from "react";
import { imagePath } from "Util/util";

const DeparturesNoService: ComponentType = ({}) => {
  return (
    <div className="departures-no-service-container">
      <img
        className="departures-no-service__image"
        src={imagePath("no-bus-service.png")}
      />
    </div>
  );
};

export default DeparturesNoService;
