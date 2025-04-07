import React, { ComponentType } from "react";
import Header from "../departures/header";

const DeparturesNoService: ComponentType = () => {
  return (
    <div className="departures-container">
      <Header {...{ title: "CONNECTIONS", arrow: null }} />
      <div className="departures-no-service">No connections available</div>
    </div>
  );
};

export default DeparturesNoService;
