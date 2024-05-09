import React, { ComponentType } from "react";
import FreeText, { FreeTextType } from "Components/v2/free_text";

type NoticeRow = {
  text: FreeTextType;
};

type Props = {
  row: NoticeRow;
};

const NoticeRow: ComponentType<Props> = ({ row }) => {
  return (
    <div className="departures__notice-row">
      <FreeText lines={{ text: row.text.text }} />
    </div>
  );
};

export default NoticeRow;
