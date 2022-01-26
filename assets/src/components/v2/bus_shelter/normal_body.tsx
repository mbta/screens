import React, { useEffect, useState } from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import makePersistent from "./persistentHOC";
import useInterval from "Hooks/use_interval";
import FlexZonePageIndicator from "Components/v2/flex/page_indicator";

interface Props {
  main_content: WidgetData;
  flex_zone: WidgetData;
  footer: WidgetData;
}

const ProofOfConceptElevatorWidget = ({ data, lastUpdate, onFinish }) => {
  const [currentPage, setCurrentPage] = useState(0);
  const [isFirstRender, setIsFirstRender] = useState(true);
  
  const totalPages = data.data ? data.data.length : 0;

  useEffect(() => {
    if (isFirstRender) {
      setIsFirstRender(false);
    } else {
      console.log('changing current page')
      setCurrentPage(i => i + 1);
    }
  }, [lastUpdate])

  useEffect(() => {
    if (currentPage === data.data.length - 1) {
      console.log("calling onFinished");
      onFinish();
    }
  }, [currentPage]);

  return (
    data.data ?
      <div>
        <div>Visible Data ID: {data.id} currentIndex: {currentPage} totalPages: {totalPages} data at currentPage: {data.data[currentPage]}</div>
        <FlexZonePageIndicator pageIndex={currentPage} numPages={totalPages} />
      </div>
      : null
  )
}

const ElevatorWidget = makePersistent(ProofOfConceptElevatorWidget)

const NormalBody: React.ComponentType<Props> = ({
  main_content: mainContent,
  flex_zone: flexZone,
  footer,
}) => {
  const [bufferedData, setBufferedData] = useState({ id: 1, data: [1, 2, 3]})

  const dummyData = [
    { id: 1, data: [1, 2, 3] },
    { id: 2, data: [1, 2] },
    { id: 3, data: [1, 2, 3, 4] },
    { id: 4, data: [1] },
  ]
  // mimic fetching background data periodically
  useInterval(() => {
    const index = Math.floor(Math.random() * 4)
    setBufferedData(dummyData[index])
    console.log('faking a new data fetch (does not match timestamp)')
  }, 10000)

  return (
    <div className="body-normal">
      <div className="body-normal__main-content">
        { <ElevatorWidget data={bufferedData} /> }
        {/* <Widget data={mainContent} /> */}
      </div>
      <div className="body-normal__flex-zone">
        {/* <Widget data={flexZone} /> */}
      </div>
      <div className="body-normal__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default NormalBody;
