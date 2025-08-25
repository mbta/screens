import type { ComponentType } from "react";
import NormalHeader from "./normal_header";
import DeparturesNoData from "./departures_no_data";
import { useStationName } from "Hooks/outfront";

// Fix station name tags without rider-facing names
export const REPLACEMENTS = {
  WTC: "World Trade Center",
  Malden: "Malden Center",
} as { [key: string]: string };

const NoData: ComponentType = () => {
  let stationName = useStationName() || "Transit information";
  stationName = REPLACEMENTS[stationName] || stationName;

  return (
    <>
      <NormalHeader text={stationName} />
      <DeparturesNoData />
    </>
  );
};

export default NoData;
