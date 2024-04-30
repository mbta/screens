import React from "react";

import { classWithModifier } from "Util/util";

const CrowdingIcon = ({ crowdingLevel }) => {
  return (
    <svg
      className={classWithModifier(
        "departure-crowding__icon",
        `level-${crowdingLevel}`,
      )}
      viewBox="0 0 110 92"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M15.6773 21.3758C21.8612 21.3758 26.8742 16.5907 26.8742 10.6879C26.8742 4.78514 21.8612 0 15.6773 0C9.49348 0 4.48047 4.78514 4.48047 10.6879C4.48047 16.5907 9.49348 21.3758 15.6773 21.3758Z"
        className={classWithModifier(
          "departure-crowding__icon-person",
          crowdingLevel >= 1 ? "active" : "inactive",
        )}
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M15.6756 27.7886C24.333 27.7886 31.3512 34.8068 31.3512 43.4642V60.6589V84.0783C31.3512 88.407 27.8421 91.9161 23.5134 91.9161H7.83781C3.50911 91.9161 0 88.407 0 84.0783V61.1386V43.4642C0 34.8068 7.01821 27.7886 15.6756 27.7886Z"
        className={classWithModifier(
          "departure-crowding__icon-person",
          crowdingLevel >= 1 ? "active" : "inactive",
        )}
      />
      <path
        d="M54.8668 21.3758C61.0506 21.3758 66.0637 16.5907 66.0637 10.6879C66.0637 4.78514 61.0506 0 54.8668 0C48.6829 0 43.6699 4.78514 43.6699 10.6879C43.6699 16.5907 48.6829 21.3758 54.8668 21.3758Z"
        className={classWithModifier(
          "departure-crowding__icon-person",
          crowdingLevel >= 2 ? "active" : "inactive",
        )}
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M54.8651 27.7886C63.5225 27.7886 70.5407 34.8068 70.5407 43.4642V60.6589V84.0783C70.5407 88.407 67.0316 91.9161 62.7029 91.9161H47.0273C42.6986 91.9161 39.1895 88.407 39.1895 84.0783V61.1386V43.4642C39.1895 34.8068 46.2077 27.7886 54.8651 27.7886Z"
        className={classWithModifier(
          "departure-crowding__icon-person",
          crowdingLevel >= 2 ? "active" : "inactive",
        )}
      />
      <path
        d="M94.0533 21.3758C100.237 21.3758 105.25 16.5907 105.25 10.6879C105.25 4.78514 100.237 0 94.0533 0C87.8695 0 82.8564 4.78514 82.8564 10.6879C82.8564 16.5907 87.8695 21.3758 94.0533 21.3758Z"
        className={classWithModifier(
          "departure-crowding__icon-person",
          crowdingLevel >= 3 ? "active" : "inactive",
        )}
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M94.0516 27.7886C102.709 27.7886 109.727 34.8068 109.727 43.4642V60.6589V84.0783C109.727 88.407 106.218 91.9161 101.889 91.9161H86.2138C81.8851 91.9161 78.376 88.407 78.376 84.0783V61.1386V43.4642C78.376 34.8068 85.3942 27.7886 94.0516 27.7886Z"
        className={classWithModifier(
          "departure-crowding__icon-person",
          crowdingLevel >= 3 ? "active" : "inactive",
        )}
      />
    </svg>
  );
};

const DepartureCrowding = ({ crowdingLevel }) => {
  return (
    <div className="departure-crowding">
      <CrowdingIcon crowdingLevel={crowdingLevel} />
    </div>
  );
};

export default DepartureCrowding;
