import {
  type ComponentType,
  type ReactNode,
  useState,
  useLayoutEffect,
  useRef,
} from "react";

import { classWithModifier, imagePath } from "Util/utils";

import RoutePill, {
  Pill,
  routePillKey,
} from "Components/departures/route_pill";

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
  LinkArrowComponent?: ComponentType;
  bodyTextMaxHeight: number;
  iconFilenameFn: (icon: AlertIcon) => string;
}

interface AlertCardProps {
  children: ReactNode;
}

type AlertIcon = "bus" | "x" | "warning" | "snowflake";

const BaseAlert: ComponentType<BaseAlertProps> = ({
  classModifier,
  alertProps: { route_pills: routePills, icon, header, body, url },
  CardComponent,
  LinkArrowComponent,
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
              routePills.length > 2 ? "small" : "regular",
            )}
          >
            {routePills.map((pill) => (
              <RoutePill
                pill={pill}
                useRouteAbbrev={true}
                key={routePillKey(pill)}
              />
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
            {LinkArrowComponent && (
              <div className="alert-widget__content__cta__link-arrow-container">
                <LinkArrowComponent />
              </div>
            )}
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
  const ref = useRef<HTMLDivElement>(null);

  /* eslint-disable-next-line react-hooks/exhaustive-deps --
   * TODO: Replace this with `useAutoSize`. For now, we know this logic cannot
   * cause infinite update loops, so we don't need to be warned that it might.
   */
  useLayoutEffect(() => {
    if (ref.current && !isSmall && ref.current.clientHeight > maxHeight) {
      setSmall(true);
    }
  });

  return (
    <div
      className={classWithModifier(
        "alert-widget__content__body-text",
        isSmall ? "small" : "regular",
      )}
      ref={ref}
    >
      {children}
    </div>
  );
};

export default BaseAlert;
export { Props, AlertCardProps, AlertIcon };
