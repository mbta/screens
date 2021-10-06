import React from "react";
import FreeText from "Components/v2/free_text";

const NoticeRow = ({ row }) => {
  return (
    <div className="departures__headway-message">
      <FreeText elements={row.text.text} />
    </div>
  );
};

export default NoticeRow;
