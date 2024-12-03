import React from "react";
import { classWithModifier } from "Util/util";

const Footer = ({ variant }: { variant: string | null }) => {
  return (
    <div className={classWithModifier("footer", variant)}>
      For more info and alternate paths: <b>mbta.com/alerts/access</b> or{" "}
      <b>617-222-2828</b>
    </div>
  );
};

export default Footer;
