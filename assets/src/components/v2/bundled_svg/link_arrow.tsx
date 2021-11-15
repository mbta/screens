import React, { ComponentType } from "react";

interface Props { }

/**
 * A right-pointing arrow. To allow it to be dynamically sized/styled by app and/or
 * location on the page without distorting the arrowhead, most of the logic lives in
 * SCSS mixins defined in link_arrow.scss.
 */
const LinkArrow: ComponentType<Props> = () => {
  return (
    <svg
      className="link-arrow"
      xmlns="http://www.w3.org/2000/svg"
      version="1.1"
    >
      <path className="link-arrow__path" />
    </svg>
  );
};

export default LinkArrow;
