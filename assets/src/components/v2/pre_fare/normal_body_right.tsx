import React, { useEffect, useState } from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import makePersistent from "../persistent_wrapper";
import FlexZonePageIndicator from "../flex/page_indicator";
import useInterval from "Hooks/use_interval";

interface Props {
  main_content_right: WidgetData;
  secondary_content: WidgetData;
}

const ProofOfConceptElevatorWidget = ({ data, lastUpdate, onFinish }) => {
  const [currentPage, setCurrentPage] = useState(0);
  const [isFirstRender, setIsFirstRender] = useState(true);
  
  const totalPages = data.data ? data.data.length : 0;

  useEffect(() => {
    if (isFirstRender) {
      setIsFirstRender(false);
    } else {
      setCurrentPage(i => i + 1);
    }
  }, [lastUpdate])

  useEffect(() => {
    if (currentPage === data.data.length - 1) {
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

const NormalBodyRight: React.ComponentType<Props> = ({
  main_content_right: mainContentRight,
  secondary_content: secondaryContent,
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
    <div className="body-normal-right">
      <div className="body-normal-right__main-content">
        <ElevatorWidget data={bufferedData} />
      </div>
      <div className="body-normal-right__secondary-content">
        <Widget data={secondaryContent} />
      </div>
    </div>
  );
};

export default NormalBodyRight;
