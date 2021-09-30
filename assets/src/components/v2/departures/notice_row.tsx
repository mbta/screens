import React from "react";
import FreeText from "Components/dup/free_text";

const NoticeRow = ({ row }) => {
  return (
    <div className="departures__headway-message">
      <FreeText lines={row.text} />
    </div>
  );
};

export default NoticeRow;
