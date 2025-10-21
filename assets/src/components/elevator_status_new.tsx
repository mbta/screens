import { type ComponentType } from "react";

import FreeText, { type FreeTextType } from "./free_text";

import NormalServiceIcon from "Images/normal-service.svg";

const className = (elementName: string | null = null) =>
  `elevator-status-new${elementName ? `__${elementName}` : ""}`;

type Props = {
  status: "ok" | "alert";
  header: string;
  header_size: "large" | "medium";
  callout_items: string[];
  footer_lines: FreeTextType[];
  cta_type: "app" | "plain";
  qr_code_url: string;
};

const ElevatorStatus: ComponentType<Props> = ({
  status,
  header,
  header_size,
  callout_items,
  footer_lines,
  cta_type,
  qr_code_url,
}) => (
  <div className={className()}>
    {status == "ok" ? (
      <>
        <div className={className("title")}>Elevator Status</div>
        <NormalServiceIcon width={160} height={160} fill="#00803b" />
      </>
    ) : (
      <div>(alert icon)</div>
    )}

    {header_size == "large" ? <h3>{header}</h3> : <h4>{header}</h4>}

    {callout_items.length > 0 && (
      <ul className="b4">
        {callout_items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    )}

    {footer_lines.length > 0 && <FreeText lines={footer_lines} />}

    {cta_type == "app" ? (
      <div className={className("cta")}>
        <div>(icon)</div>
        <div>
          <p className="b3">
            Live elevator alerts on <b>MBTA Go</b>
          </p>
          <p className="b2">
            <b>mbta.com/go-access</b>
          </p>
        </div>
        <div>(QR code: {qr_code_url})</div>
      </div>
    ) : (
      <div>(QR code: {qr_code_url})</div>
    )}
  </div>
);

export default ElevatorStatus;
