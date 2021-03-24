import React from "react";
import { classWithModifier, imagePath } from "Util/util";
import _ from "lodash";

interface Props {
  pill: string;
  icon: string;
  active_status: "active" | "upcoming";
  header: string;
  text: string[];
}

const Alert: React.ComponentType<Props> = ({
  icon,
  active_status: activeStatus,
  header,
  text,
}) => {
  return (
    <div className={classWithModifier("alert-normal", activeStatus)}>
      {activeStatus === "upcoming" ? (
        <div className="alert-normal__upcoming-text">upcoming</div>
      ) : (
        <div className="alert-normal__icon">{`<${icon} icon>`}</div>
      )}
      <div className="alert-normal__header">{header}</div>
      <div className="alert-normal__text">{text[0]}</div>
      <div className="alert-normal__footer">mbta.com/alerts</div>
    </div>
  );
};

export default Alert;
