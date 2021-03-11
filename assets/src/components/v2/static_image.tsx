import React from "react";

interface Props {
  url: string;
}

const StaticImage: React.ComponentType<Props> = ({ url }) => {
  return (
    <div className="static-image">
      <img src={url} />
    </div>
  );
};

export default StaticImage;
