import React from "react";

import { imagePath } from "Util/util";
import DefaultLinkFooter from "Components/v2/link_footer";

const LinkFooter = ({ text, url }) => {
  return <DefaultLinkFooter text={text} url={url} logoPath="logo-black.svg" />;
};

export default LinkFooter;
