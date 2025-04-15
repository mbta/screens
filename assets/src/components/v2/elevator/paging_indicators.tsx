import React from "react";
import PagingDotUnselected from "Images/paging_dot_unselected.svg";
import PagingDotSelected from "Images/paging_dot_selected.svg";

interface PagingIndicatorsProps {
  numPages: number;
  pageIndex: number;
}

const PagingIndicators = ({ numPages, pageIndex }: PagingIndicatorsProps) => {
  const indicators: JSX.Element[] = [];
  for (let i = 0; i < numPages; i++) {
    const indicator =
      pageIndex === i ? (
        <PagingDotSelected
          className="paging-indicator"
          height={40}
          width={40}
          key={i}
        />
      ) : (
        <PagingDotUnselected
          className="paging-indicator"
          height={28}
          width={28}
          key={i}
        />
      );
    indicators.push(indicator);
  }

  return <div className="paging-indicators">{indicators}</div>;
};

export default PagingIndicators;
