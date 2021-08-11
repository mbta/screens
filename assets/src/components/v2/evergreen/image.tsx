import React, { ComponentType } from "react";

interface Props {
  imageUrl: string;
}

const Image: ComponentType<Props> = ({ imageUrl }) => {
  return (
    <div className="evergreen-content-image__container">
      <img className="evergreen-content-image__image" src={imageUrl} />
    </div>
  );
};

export default Image;
