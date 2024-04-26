import useTextResizer from "Hooks/v2/use_text_resizer";
import React from "react";
import { getHexColor, STRING_TO_SVG } from "Util/svg_utils";
import DisruptionDiagram, {
  DisruptionDiagramData,
} from "./disruption_diagram/disruption_diagram";
import { classWithModifier, classWithModifiers, formatCause } from "Util/util";

import ClockIcon from "../../../static/images/svgr_bundled/clock-negative.svg";
import NoServiceIcon from "../../../static/images/svgr_bundled/no-service.svg";
import InfoIcon from "../../../static/images/svgr_bundled/info.svg";
import ISAIcon from "../../../static/images/svgr_bundled/isa.svg";
import WalkingIcon from "../../../static/images/svgr_bundled/nearby.svg";
import ShuttleBusIcon from "../../../static/images/svgr_bundled/bus.svg";

interface PreFareSingleScreenAlertProps {
  issue: string;
  location: string;
  cause: string;
  remedy: string;
  remedy_bold?: string;
  routes: EnrichedRoute[];
  unaffected_routes: EnrichedRoute[];
  endpoints: string[];
  effect: string;
  region: string;
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

// Bypassed station alerts can have resizing font based on how many stations are affected
// Other alerts have static font sizes:
// - issue font is size large
// - "Seek alternate route" remedy is medium
// - "Use shuttle bus" remedy is large
const StandardLayout: React.ComponentType<StandardLayoutProps> = ({
  issue,
  remedy,
  effect,
  location,
  disruptionDiagram,
}) => {
  const maxTextHeight = 772;

  const { ref: contentBlockRef, size: contentTextSize } = useTextResizer({
    sizes: ["medium", "large"],
    // the 32 is padding on the text object
    maxHeight: maxTextHeight + 32,
    resetDependencies: [issue, remedy],
  });

  return (
    <div className="alert-card__content-block">
      <div ref={contentBlockRef}>
        <StandardIssueSection
          issue={issue}
          location={location}
          contentTextSize={
            effect === "station_closure" ? contentTextSize : "large"
          }
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
  endpoints: string[];
  effect: string;
  remedy: string;
  disruptionDiagram?: DisruptionDiagramData;
}

// In the downstream layout, the map is at the top, and the font size stays constant
const DownstreamLayout: React.ComponentType<DownstreamLayoutProps> = ({
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

interface MultiLineLayoutProps {
  routes: EnrichedRoute[];
  unaffected_routes: EnrichedRoute[];
  disruptionDiagram?: DisruptionDiagramData;
}

// Covers the case where a station_closure only affects one line at a transfer station.
// In the even rarer case that there are multiple branches in the routes list or unaffected routes list
// the font size may need to shrink to accommodate.
const MultiLineLayout: React.ComponentType<MultiLineLayoutProps> = ({
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

const FallbackLayout: React.ComponentType<FallbackLayoutProps> = ({
  issue,
  remedy,
  remedyBold,
  effect,
}) => {
  const { ref: pioTextBlockRef, size: pioSecondaryTextSize } = useTextResizer({
    sizes: ["small", "medium"],
    maxHeight: 460,
    resetDependencies: [issue, remedy],
  });

  const icon =
    effect === "delay" ? (
      <ClockIcon className="alert-card__fallback__icon" />
    ) : effect === "shuttle" ? (
      <ShuttleBusIcon className="alert-card__fallback__icon" />
    ) : (
      <NoServiceIcon className="alert-card__fallback__icon" />
    );

  return (
    <div className="alert-card__fallback">
      {icon}
      {issue && <div className="alert-card__fallback__issue-text">{issue}</div>}
      {remedy && (
        <div
          className={classWithModifier(
            "alert-card__fallback__pio-text",
            pioSecondaryTextSize,
          )}
          ref={pioTextBlockRef}
        >
          {remedy}
        </div>
      )}
      {remedyBold && (
        <div className="alert-card__fallback__pio-text alert-card__fallback__pio-text--bold">
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

const StandardIssueSection: React.ComponentType<StandardIssueSectionProps> = ({
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
  endpoints: string[];
}

const DownstreamIssueSection: React.ComponentType<
  DownstreamIssueSectionProps
> = ({ endpoints }) => (
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
const RemedySection: React.ComponentType<RemedySectionProps> = ({
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

const MapSection: React.ComponentType<MapSectionProps> = ({
  disruptionDiagram,
}) => {
  return (
    <div
      id="disruption-diagram-container"
      className="disruption-diagram-container"
    >
      <DisruptionDiagram {...disruptionDiagram} />
    </div>
  );
};

const isMultiLine = (effect: string, region: string) =>
  effect === "station_closure" && region === "here";

const PreFareSingleScreenAlert: React.ComponentType<
  PreFareSingleScreenAlertProps
> = (alert) => {
  const {
    cause,
    region,
    effect,
    endpoints,
    issue,
    location,
    remedy,
    remedy_bold,
    routes,
    unaffected_routes,
    updated_at,
    disruption_diagram,
  } = alert;

  /**
   * This switch statement picks the alert layout
   * - fallback: icon, followed by a summary & pio text, or just the pio text
   * - multiline: icon + route pill + text explaining the lines that are closed at the station
   *              and then icon + route pill + text explaining normal service. Finally, the map section
   * - standard: icon + issue, and icon + remedy, and then map section
   * - downstream: map, issue without icon, then icon + remedy
   **/
  let layout;
  switch (true) {
    case effect === "delay":
      layout = <FallbackLayout issue={issue} remedy={remedy} effect={effect} />;
      break;
    case !disruption_diagram:
      layout = (
        <FallbackLayout
          issue={issue}
          remedy={remedy}
          remedyBold={remedy_bold}
          effect={effect}
        />
      );
      break;
    case effect === "station_closure" && region === "here":
      layout = (
        <MultiLineLayout
          routes={routes}
          unaffected_routes={unaffected_routes}
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
      layout = (
        <FallbackLayout
          issue={issue}
          remedy={remedy}
          remedyBold={remedy_bold}
          effect={effect}
        />
      );
  }

  const showBanner = !isMultiLine(effect, region);

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

const PreFareAlertBanner: React.ComponentType<{ routes: EnrichedRoute[] }> = ({
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
