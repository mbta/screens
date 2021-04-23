import React from "react";

import { imagePath } from "Util/util";

const LinkFooter = ({ text, url, logoPath }) => {
  return (
    <div className="link-footer">
      <div className="link-footer__contents">
        <div className="link-footer__logo">
          <img className="link-footer__logo-image" src={imagePath(logoPath)} />
        </div>
        <div className="link-footer__message">
          <span className="link-footer__message-text">{text} </span>
          <span className="link-footer__message-url">{url}</span>
        </div>
      </div>
    </div>
  );
};

export default LinkFooter;
