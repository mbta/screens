import React, { ComponentType, useState, useLayoutEffect, useRef } from "react";
import { classWithModifier, imagePath } from "Util/util";

import RoutePill, {
  Pill,
  routePillKey,
} from "Components/v2/departures/route_pill";

import LinkArrow from "Components/v2/bundled_svg/link_arrow";

interface Props {
  route_pills: Pill[];
  icon: AlertIcon;
  header: string;
  body: string;
  url: string;
}

interface BaseAlertProps {
  alertProps: Props;
  classModifier: string;
  CardComponent: ComponentType<AlertCardProps>;
  bodyTextMaxHeight: number;
  iconFilenameFn: (icon: AlertIcon) => string;
}

interface AlertCardProps {
  children: React.ReactNode;
}

type AlertIcon = "bus" | "x" | "warning" | "snowflake";

const BaseAlert: ComponentType<BaseAlertProps> = ({
  classModifier,
  alertProps: { route_pills: routePills, icon, header, body, url },
  CardComponent,
  bodyTextMaxHeight,
  iconFilenameFn,
}) => {
  return (
    <div className={classWithModifier("alert-widget", classModifier)}>
      <CardComponent>
        <div className="alert-widget__content">
          <div
            className={classWithModifier(
              "alert-widget__content__route-pills",
              routePills.length > 2 ? "small" : "regular"
            )}
          >
            {routePills.map((pill) => (
              <RoutePill {...pill} key={routePillKey(pill)} />
            ))}
          </div>
          <div className="alert-widget__content__icon">
            <img
              className="alert-widget__content__icon-image"
              src={imagePath(iconFilenameFn(icon))}
            />
          </div>
          <div className="alert-widget__content__header-text">{header}</div>
          <BodyTextSizer maxHeight={bodyTextMaxHeight} key={body}>
            {body}
          </BodyTextSizer>
          <div className="alert-widget__content__cta">
            <div className="alert-widget__content__cta__icon">
              <img
                className="alert-widget__content__cta__icon__image"
                src={imagePath("logo-white.svg")}
              />
            </div>
            <div className="alert-widget__content__cta__link-arrow-container">
              <LinkArrow />
            </div>
            <div className="alert-widget__content__cta__url">{url}</div>
          </div>
        </div>
      </CardComponent>
    </div>
  );
};

interface BodyTextSizerProps {
  children: string;
  maxHeight: number;
}

const BodyTextSizer: ComponentType<BodyTextSizerProps> = ({
  children,
  maxHeight,
}) => {
  const [isSmall, setSmall] = useState(false);
  const ref = useRef(null);

  useLayoutEffect(() => {
    if (ref.current && !isSmall && ref.current.clientHeight > maxHeight) {
      setSmall(true);
    }
  });

  return (
    <div
      className={classWithModifier(
        "alert-widget__content__body-text",
        isSmall ? "small" : "regular"
      )}
      ref={ref}
    >
      {children}
    </div>
  );
};

export default BaseAlert;
export { Props, AlertCardProps, AlertIcon };
