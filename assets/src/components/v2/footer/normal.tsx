import React from "react";

interface Props {
  url: string;
}

const NormalFooter: React.ComponentType<Props> = ({ url }) => {
  return (
    <div className="footer-normal">
      <div className="footer-normal__url">On the go: <em>{url}</em></div>
    </div>
  );
};

export default NormalFooter;
