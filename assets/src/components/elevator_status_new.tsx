import cx from "classnames";
import { QRCodeSVG as QRCode } from "qrcode.react";
import { type ComponentType } from "react";

import FreeText, { type FreeTextType } from "./free_text";

import useAutoSize from "Hooks/use_auto_size";
import { classWithModifier } from "Util/utils";

import AppInHandIcon from "Images/app-in-hand.svg";
import ElevatorAlertIcon from "Images/isa-alert-badge.svg";
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
}) => {
  const { ref, step: calloutClassName } = useAutoSize(
    ["header-4", "body-2", "body-4", "body-4 overflow"],
    header_size + header + callout_items.join() + JSON.stringify(footer_lines),
  );

  return (
    <div className={className()} ref={ref}>
      {status === "ok" && (
        <div className={className("title")}>Elevator Status</div>
      )}

      <div className={className("body")}>
        {status === "ok" ? (
          <NormalServiceIcon width={160} height={160} fill="#00803b" />
        ) : (
          <ElevatorAlertIcon width={280} height={160} />
        )}

        <div className={className("header")}>
          {header_size === "large" ? <h3>{header}</h3> : <h4>{header}</h4>}

          {callout_items.length > 0 && (
            <ul className={calloutClassName}>
              {callout_items.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          )}
        </div>

        <div className={className("footer")}>
          {footer_lines.length > 0 && (
            <FreeText className="body-4" lines={footer_lines} />
          )}

          {cta_type === "plain" && (
            <QRCode marginSize={2} size={128} value={qr_code_url} />
          )}
        </div>
      </div>

      {cta_type === "app" && (
        <AppCTA
          className={className("cta")}
          qrCodeUrl={qr_code_url}
          size={footer_lines.length > 0 ? "small" : "large"}
        />
      )}
    </div>
  );
};

const AppCTA = ({ className, qrCodeUrl, size }) => (
  <div
    className={cx(className, classWithModifier("elevator-alerts-cta", size))}
  >
    <AppInHandIcon className="elevator-alerts-cta__icon" />

    <div className="elevator-alerts-cta__text">
      <div className="body-3">
        Live elevator alerts on <b>MBTA Go</b>
      </div>
      <div className="body-2">
        <b>mbta.com/go-access</b>
      </div>
    </div>

    <QRCode
      className="elevator-alerts-cta__qrcode"
      marginSize={2}
      size={144}
      value={qrCodeUrl}
    />
  </div>
);

export default ElevatorStatus;
