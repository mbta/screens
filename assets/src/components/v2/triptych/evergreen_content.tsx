import React, { ComponentType } from "react";
import { TRIPTYCH_VERSION } from "./version";
import { usePlayerName } from "Hooks/outfront";
import BaseEvergreenContent from "../evergreen_content";

interface Props {
  asset_url: string;
  show_identifiers: boolean;
}

const EvergreenContent: ComponentType<Props> = (props) => {
  console.log(props);
  const { show_identifiers: showIdentifiers } = props;
  const playerName = usePlayerName();
  let identifiers = `${TRIPTYCH_VERSION} ${playerName ? playerName : ""}`;

  return (
    <>
      <BaseEvergreenContent {...props} />
      {showIdentifiers && (
        <div className="evergreen-content__identifiers">{identifiers}</div>
      )}
    </>
  );
};

export default EvergreenContent;
