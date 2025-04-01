import React from "react";

const ConnectionsHeader = ({ text }) => {
  return (
    <div className={"connections_header"}>
      <div className={"connections_header__text"}>{text}</div>;
    </div>
  );
};

export default ConnectionsHeader;
