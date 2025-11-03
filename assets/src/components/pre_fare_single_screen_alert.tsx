import type { ComponentType } from "react";

import useAutoSize from "Hooks/use_auto_size";
import { getHexColor, STRING_TO_SVG } from "Util/svg_utils";
import { classWithModifier, classWithModifiers, formatCause } from "Util/utils";

import DisruptionDiagram, {
  DisruptionDiagramData,
} from "./disruption_diagram/disruption_diagram";

import ClockIcon from "Images/clock-negative.svg";
import NoServiceIcon from "Images/no-service.svg";
import InfoIcon from "Images/info.svg";
import ISAIcon from "Images/isa.svg";
import WalkingIcon from "Images/nearby.svg";
import ShuttleBusIcon from "Images/bus.svg";

interface PreFareSingleScreenAlertProps {
  issue: string;
  location: string;
  cause: string;
  remedy: string;
  routes: EnrichedRoute[];
  unaffected_routes?: EnrichedRoute[];
  endpoints: [string, string];
  effect:
    | "suspension"
    | "shuttle"
    | "station_closure"
    | "delay"
    | "information";
  region: "here" | "boundary" | "outside";
  updated_at: string;
  disruption_diagram?: DisruptionDiagramData;
}

interface EnrichedRoute {
  route_id: string;
  svg_name: string;
}

interface StandardLayoutProps {
  issue: string;
  remedy: string;
  effect: string;
  location: string | null;
  disruptionDiagram?: DisruptionDiagramData;
}

const StandardLayout: ComponentType<StandardLayoutProps> = ({
  issue,
  remedy,
  effect,
  location,
  disruptionDiagram,
}) => {
  // For station closure alerts, content may need to be sized down depending on
  // how many stations are affected
  const { ref: textRef, step: issueTextSize } = useAutoSize(
    effect === "station_closure" ? ["large", "medium"] : ["large"],
    issue + remedy,
  );

  return (
    <div className="alert-card__content-block">
      <div className="alert-card__content-block__text-sections" ref={textRef}>
        <StandardIssueSection
          issue={issue}
          location={location}
          contentTextSize={issueTextSize}
        />
        <RemedySection
          effect={effect}
          remedy={remedy}
          contentTextSize="large"
        />
      </div>
      {disruptionDiagram && (
        <MapSection disruptionDiagram={disruptionDiagram} />
      )}
    </div>
  );
};

interface DownstreamLayoutProps {
  endpoints: [string, string];
  effect: string;
  remedy: string;
  disruptionDiagram?: DisruptionDiagramData;
}

// In the downstream layout, the map is at the top, and the font size stays constant
const DownstreamLayout: ComponentType<DownstreamLayoutProps> = ({
  endpoints,
  effect,
  remedy,
  disruptionDiagram,
}) => (
  <div className={classWithModifier("alert-card__content-block", "downstream")}>
    {disruptionDiagram && <MapSection disruptionDiagram={disruptionDiagram} />}
    <DownstreamIssueSection endpoints={endpoints} />
    <RemedySection effect={effect} remedy={remedy} contentTextSize="medium" />
  </div>
);

interface PartialClosureLayoutProps {
  routes: EnrichedRoute[];
  unaffected_routes: EnrichedRoute[];
  disruptionDiagram?: DisruptionDiagramData;
}

// Covers the case where a station_closure only affects one line at a transfer station.
// In the even rarer case that there are multiple branches in the routes list or unaffected routes list
// the font size may need to shrink to accommodate.
const PartialClosureLayout: ComponentType<PartialClosureLayoutProps> = ({
  routes,
  unaffected_routes,
  disruptionDiagram,
}) => {
  const AffectedLinePill = STRING_TO_SVG[routes[0].svg_name];
  const affectedLineColor = getHexColor(getRouteColor(routes[0].route_id));

  return (
    <div className="alert-card__content-block">
      <div className="alert-card__issue">
        <NoServiceIcon className="alert-card__icon" />
        <div className="alert-card__content-block__text--large">
          <AffectedLinePill
            className="alert-card__content-block__route-pill"
            color={affectedLineColor}
          />
          <span>trains are skipping this station</span>
        </div>
      </div>
      <div className="alert-card__issue">
        <InfoIcon className="alert-card__icon" />
        <div className="alert-card__content-block__text--large">
          {unaffected_routes.map((route) => {
            const UnaffectedLinePill = STRING_TO_SVG[route.svg_name];
            const unaffectedLineColor = getHexColor(
              getRouteColor(route.route_id),
            );
            return (
              <UnaffectedLinePill
                key={route.route_id}
                className="alert-card__content-block__route-pill"
                color={unaffectedLineColor}
              />
            );
          })}
          <span>trains stop as usual</span>
        </div>
      </div>
      {disruptionDiagram && (
        <MapSection disruptionDiagram={disruptionDiagram} />
      )}
    </div>
  );
};

interface FallbackLayoutProps {
  issue: string;
  remedy: string;
  remedyBold?: string;
  effect: string;
}

const fallbackLayoutIcons = {
  delay: ClockIcon,
  information: InfoIcon,
  shuttle: ShuttleBusIcon,
};

const FallbackLayout: ComponentType<FallbackLayoutProps> = ({
  issue,
  remedy,
  remedyBold,
  effect,
}) => {
  const { ref: alertTextRef, step: alertTextSize } = useAutoSize(
    ["body-1", "body-2", "body-3", "body-4"],
    remedy,
  );

  const Icon = fallbackLayoutIcons[effect] ?? NoServiceIcon;

  return (
    <div className="alert-card__fallback">
      <Icon className="alert-card__fallback__icon" />
      {issue && <div className="alert-card__fallback__issue-text">{issue}</div>}
      {remedy && (
        <div
          className={`alert-card__fallback__alert-text ${alertTextSize}`}
          ref={alertTextRef}
        >
          {remedy}
        </div>
      )}
      {remedyBold && (
        <div className="alert-card__fallback__alert-text alert-card__fallback__alert-text--bold">
          {remedyBold}
        </div>
      )}
    </div>
  );
};

interface StandardIssueSectionProps {
  issue: string;
  location: string | null;
  contentTextSize: string;
}

const StandardIssueSection: ComponentType<StandardIssueSectionProps> = ({
  issue,
  location,
  contentTextSize,
}) => (
  <div className="alert-card__issue">
    <NoServiceIcon className="alert-card__icon" />
    <div>
      <div
        className={classWithModifier(
          "alert-card__content-block__text",
          contentTextSize,
        )}
      >
        {issue}
      </div>
      {location && (
        <div className="alert-card__issue__location">{location}</div>
      )}
    </div>
  </div>
);

interface DownstreamIssueSectionProps {
  endpoints: [string, string];
}

const DownstreamIssueSection: ComponentType<DownstreamIssueSectionProps> = ({
  endpoints,
}) => (
  <div className="alert-card__issue">
    <div
      className={classWithModifier("alert-card__content-block__text", "medium")}
    >
      No trains <span style={{ fontWeight: 500 }}>between</span> {endpoints[0]}{" "}
      <span style={{ fontWeight: 500 }}>&</span> {endpoints[1]}
    </div>
  </div>
);
interface RemedySectionProps {
  effect: string;
  remedy: string | null;
  contentTextSize: string;
}
const RemedySection: ComponentType<RemedySectionProps> = ({
  effect,
  remedy,
  contentTextSize,
}) => (
  <div className="alert-card__remedy">
    {effect === "shuttle" ? (
      <>
        <div className="alert-card__remedy__shuttle-icons">
          <ShuttleBusIcon className="alert-card__icon" />
          <ISAIcon className="alert-card__isa-icon" />
        </div>
        <div>
          <div
            className={classWithModifier(
              "alert-card__content-block__text",
              contentTextSize,
            )}
          >
            {remedy}
          </div>
          <div className="alert-card__body__accessibility-info--text">
            All shuttle buses are accessible
          </div>
        </div>
      </>
    ) : (
      <>
        <WalkingIcon className="alert-card__icon" />
        <div className="alert-card__remedy__text">{remedy}</div>
      </>
    )}
  </div>
);

interface MapSectionProps {
  disruptionDiagram: DisruptionDiagramData;
}

const MapSection: ComponentType<MapSectionProps> = ({ disruptionDiagram }) => {
  return (
    <div
      id="disruption-diagram-container"
      className="disruption-diagram-container"
    >
      <DisruptionDiagram {...disruptionDiagram} />
    </div>
  );
};

const isPartialClosure = ({
  effect,
  region,
  unaffected_routes,
}: PreFareSingleScreenAlertProps): boolean =>
  effect === "station_closure" &&
  region === "here" &&
  unaffected_routes !== undefined &&
  unaffected_routes.length > 0;

const PreFareSingleScreenAlert: ComponentType<PreFareSingleScreenAlertProps> = (
  alert,
) => {
  const {
    cause,
    region,
    effect,
    endpoints,
    issue,
    location,
    remedy,
    routes,
    unaffected_routes,
    updated_at,
    disruption_diagram,
  } = alert;

  /**
   * This switch statement picks the alert layout
   * - fallback: icon, followed by a summary & pio text, or just the pio text
   * - partial closure: icon + route pill + text explaining the lines that are closed at the station
   *                    and then icon + route pill + text explaining normal service. Finally, the map section
   * - standard: icon + issue, and icon + remedy, and then map section
   * - downstream: map, issue without icon, then icon + remedy
   **/
  let layout;
  switch (true) {
    case effect === "delay" || !disruption_diagram:
      layout = <FallbackLayout issue={issue} remedy={remedy} effect={effect} />;
      break;
    case isPartialClosure(alert):
      // By definition if `isPartialClosure` is true then `unaffected_routes` is
      // present, so it's okay to use a non-null assertion here.
      layout = (
        <PartialClosureLayout
          routes={routes}
          unaffected_routes={unaffected_routes!}
          disruptionDiagram={disruption_diagram}
        />
      );
      break;
    case effect === "station_closure" && region === "here":
      layout = (
        <StandardLayout
          issue={issue}
          remedy={remedy}
          effect={effect}
          location={location}
          disruptionDiagram={disruption_diagram}
        />
      );
      break;
    case effect === "station_closure":
      layout = (
        <StandardLayout
          issue={issue}
          remedy={remedy}
          effect={effect}
          location={location}
          disruptionDiagram={disruption_diagram}
        />
      );
      break;
    case (region === "boundary" || region === "here") &&
      (effect === "shuttle" || effect === "suspension"):
      layout = (
        <StandardLayout
          issue={issue}
          remedy={remedy}
          effect={effect}
          location={location}
          disruptionDiagram={disruption_diagram}
        />
      );
      break;
    case region === "outside" &&
      endpoints &&
      (effect === "shuttle" || effect === "suspension"):
      layout = (
        <DownstreamLayout
          endpoints={endpoints}
          effect={effect}
          remedy={remedy}
          disruptionDiagram={disruption_diagram}
        />
      );
      break;
    default:
      layout = <FallbackLayout issue={issue} remedy={remedy} effect={effect} />;
  }

  const showBanner = !isPartialClosure(alert);

  return (
    <div className="pre-fare-alert__page">
      {showBanner && <PreFareAlertBanner routes={routes} />}
      <div
        className={classWithModifiers("alert-container", [
          "single-page",
          getAlertColor(routes),
          showBanner ? "with-banner" : "no-banner",
        ])}
      >
        <div
          className={classWithModifier(
            "alert-card",
            showBanner ? "with-banner" : "no-banner",
          )}
        >
          <div className={classWithModifier("alert-card__body", effect)}>
            {layout}
          </div>
          <div className="alert-card__footer">
            {cause && (
              <div className="alert-card__footer__cause">
                Cause: {formatCause(cause)}
              </div>
            )}
            <div>
              Updated{" "}
              <span className="alert-card__footer__datetime">{updated_at}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const getRouteColor = (route_id: string) => {
  switch (route_id.substring(0, 3)) {
    case "Red":
      return "red";
    case "Ora":
      return "orange";
    case "Blu":
      return "blue";
    case "Gre":
      return "green";
    default:
      return "yellow";
  }
};

// If only one route color is represented ("gl-union" and "gl-riverside" are the same route color)
// use that, otherwise "yellow"
const getAlertColor = (routes: EnrichedRoute[]) => {
  const colors = routes.map((r) => getRouteColor(r.route_id));
  const uniqueColors = new Set(colors).size;
  return uniqueColors == 1 ? colors[0] : "yellow";
};

const PreFareAlertBanner: ComponentType<{ routes: EnrichedRoute[] }> = ({
  routes,
}) => {
  let banner;

  if (
    routes.length === 1 &&
    ["rl", "ol", "bl", "gl", "gl-b", "gl-c", "gl-d", "gl-e"].includes(
      routes[0].svg_name,
    )
  ) {
    // One destination, short text
    const route = routes[0];
    const LinePill = STRING_TO_SVG[route.svg_name];
    const color = getRouteColor(route.route_id);

    banner = (
      <div className={classWithModifiers("alert-banner", ["small", color])}>
        <span className="alert-banner__attention-text">ATTENTION</span>
        <LinePill
          className="alert-banner__route-pill--short"
          color={getHexColor(color)}
        />
        <span>riders</span>
      </div>
    );
  } else if (routes.length === 1) {
    // One destination, long text
    const route = routes[0];
    const LinePill = STRING_TO_SVG[route.svg_name];
    const color = getRouteColor(route.route_id);

    banner = (
      <div
        className={classWithModifiers("alert-banner", [
          "large--one-route",
          color,
        ])}
      >
        <span>
          <span className="alert-banner__attention-text">ATTENTION,</span>{" "}
          riders to
        </span>
        <LinePill
          className="alert-banner__route-pill--long"
          color={getHexColor(color)}
        />
      </div>
    );
  } else if (routes.length === 2) {
    // Two destinations
    banner = (
      <div
        className={classWithModifiers("alert-banner", [
          "large--two-routes",
          getAlertColor(routes),
        ])}
      >
        <span>
          <span className="alert-banner__attention-text">ATTENTION,</span>{" "}
          riders to
        </span>
        {routes.map((route) => {
          const LinePill = STRING_TO_SVG[route.svg_name];
          return (
            <LinePill
              className="alert-banner__route-pill--long"
              key={route.svg_name}
              color={getHexColor(getRouteColor(route.route_id))}
            />
          );
        })}
      </div>
    );
  } else {
    // Fallback
    banner = (
      <div
        className={classWithModifiers("alert-banner", [
          "small",
          getAlertColor(routes),
        ])}
      >
        <span>
          <span className="alert-banner__attention-text">ATTENTION,</span>{" "}
          riders
        </span>
      </div>
    );
  }

  return banner;
};

export default PreFareSingleScreenAlert;
