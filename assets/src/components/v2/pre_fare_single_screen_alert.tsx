import useTextResizer from "Hooks/v2/use_text_resizer";
import React from "react";
import { getHexColor, STRING_TO_SVG } from "Util/svg_utils";

import { classWithModifier, classWithModifiers, formatCause } from "Util/util";

import ClockIcon from "../../../static/images/svgr_bundled/clock-negative.svg"
import NoServiceIcon from "../../../static/images/svgr_bundled/no-service.svg";
import InfoIcon from "../../../static/images/svgr_bundled/info.svg";
import ISAIcon from "../../../static/images/svgr_bundled/isa.svg";
import WalkingIcon from "../../../static/images/svgr_bundled/nearby.svg"
import ShuttleBusIcon from "../../../static/images/svgr_bundled/bus.svg"

interface PreFareSingleScreenAlertProps {
  issue: string;
  location: string;
  cause: string;
  remedy: string;
  routes: string[];
  unaffected_routes: string[];
  endpoints: string[];
  effect: string;
  region: string;
  updated_at: string;
}

// For the standard layout, issue font can be medium or large. 
// If remedy is "Seek alternate route", font size is static. Otherwise, it uses the same font size as
// the issue.
const standardLayout = (issue: string, remedy: string, effect: string, location: string | null) => {
  const { ref: contentBlockRef, size: contentTextSize } = useTextResizer({
    sizes: ["medium", "large"],
    maxHeight: 772,
    resetDependencies: [issue, remedy],
  });

  return (
    <div className="alert-card__content-block" ref={contentBlockRef}>
      {standardIssueSection(issue, location, contentTextSize)}
      {remedySection(effect, remedy, contentTextSize)}
      {mapSection()}
    </div>
  )
}

// In the downstream layout, the map is at the top, and the font size stays constant
const downstreamLayout = (endpoints: string[], effect: string, remedy: string) => (
  <div className={classWithModifier("alert-card__content-block", "downstream")}>
    {mapSection()}
    {downstreamIssueSection(endpoints)}
    {remedySection(effect, remedy, "medium")}
  </div>
)

// Covers the case where a station_closure only affects one line at a transfer station.
// In the even rarer case that there are multiple branches in the routes list or unaffected routes list
// the font size may need to shrink to accommodate.
const multiLineLayout = (routes: string[], unaffected_routes: string[]) => {
  const AffectedLinePill = STRING_TO_SVG[routes[0]]

  return (
    <div className="alert-card__content-block">
      <div className="alert-card__issue">
        <NoServiceIcon className="alert-card__icon" />
        <div className="alert-card__content-block__text--large">
          <AffectedLinePill
            className="alert-card__content-block__route-pill"
            color={getHexColor(getRouteColor(routes[0]))} />
          <span>trains are skipping this station</span>
        </div>
      </div>
      <div className="alert-card__issue">
        <InfoIcon className="alert-card__icon" />
        <div className="alert-card__content-block__text--large">
          {unaffected_routes.map(route => {
            const UnaffectedLinePill = STRING_TO_SVG[route]
            return <UnaffectedLinePill className="alert-card__content-block__route-pill" color={getHexColor(getRouteColor(route))} />
          })}
          <span>trains stop as usual</span>
        </div>
      </div>
      {mapSection()}
    </div>
  )
}

const fallbackLayout = (issue: string, remedy: string, effect: string, routes: string[]) => {
  // If there is more than 1 route in the banner, or the 1 route is longer than "GL·B"
  // the banner will be tall. Otherwise, it'll be 1-line
  const bannerHeight = (routes.length > 1 || (routes[0] && routes[0].length > 4)) ? 368 : 200

  const screenHeight = 1720, footerHeight = 84, bottomMargin = 32, alertCardPadding = 120 + 32

  const maxTextHeight = screenHeight - footerHeight - bottomMargin - alertCardPadding - bannerHeight

  const { ref: pioTextBlockRef, size: pioSecondaryTextSize } = useTextResizer({
    sizes: ["small", "medium"],
    maxHeight: maxTextHeight,
    resetDependencies: [issue, remedy],
  });

  const icon = effect === "delay"
    ? <ClockIcon className="alert-card__pio-text__icon" />
    : effect === "shuttle" ? <ShuttleBusIcon className="alert-card__pio-text__icon" /> : <NoServiceIcon className="alert-card__pio-text__icon" />


  return (
    <div className="alert-card__pio-text" ref={pioTextBlockRef}>
      {icon}
      {issue && <div className="alert-card__pio-text__main-text">{issue}</div>}
      {remedy && <div className={classWithModifier("alert-card__pio-text__secondary-text", pioSecondaryTextSize)}>{remedy}</div>}
    </div>
  )
}

const standardIssueSection = (issue: string, location: string | null, textSize: string) => (
  <div className="alert-card__issue">
    <NoServiceIcon className="alert-card__icon" />
    <div>
      <div className={classWithModifier("alert-card__content-block__text", textSize)}>
        {issue}
      </div>
      {location && <div className="alert-card__issue__location">{location}</div>}
    </div>
  </div>
)

const downstreamIssueSection = (endpoints: string[]) => (
  <div className="alert-card__issue">
    <div className={classWithModifier("alert-card__content-block__text", "medium")}>
      No trains <span style={{fontWeight: 500}}>between</span> {endpoints[0]} <span style={{fontWeight: 500}}>&</span> {endpoints[1]}
    </div>
  </div>
)

const remedySection = (effect: string, remedy: string | null, contentTextSize: string) => (
  <div className="alert-card__remedy">
    { effect === "shuttle" ?
      <>
        <div className="alert-card__remedy__shuttle-icons">
          <ShuttleBusIcon className="alert-card__icon" />
          <ISAIcon className="alert-card__isa-icon" />
        </div>
        <div>
          <div className={classWithModifier("alert-card__content-block__text", contentTextSize)}>
            {remedy}
          </div>
          <div className="alert-card__body__accessibility-info--text">
            All shuttle buses are accessible
          </div>
        </div>
      </>
      : <>
        <WalkingIcon className="alert-card__icon" />
        <div className="alert-card__remedy__text">{remedy}</div>
      </>
    }
  </div>
)

const mapSection = () => {
  <></>
}

const isMultiLine = (effect: string, region: string) => effect === "station_closure" && region === "here"

const PreFareSingleScreenAlert: React.ComponentType<PreFareSingleScreenAlertProps> = (alert) => {
  const { cause, region, effect, endpoints, issue, location, remedy, routes, unaffected_routes, updated_at } = alert;

  /** 
  * This switch statement picks the alert layout
  * - fallback: icon, followed by a summary & pio text, or just the pio text
  * - multiline: icon + route pill + text explaining the lines that are closed at the station
  *              and then icon + route pill + text explaining normal service. Finally, the map section
  * - standard: icon + issue, and icon + remedy, and then map section
  * - downstream: map, issue without icon, then icon + remedy
  **/
  const layoutRenderer = () => {
    switch(true) {
      case effect === "delay":
        return fallbackLayout(issue, remedy, effect, routes)
      case effect === "station_closure" && region === "here":
        return multiLineLayout(routes, unaffected_routes)
      case effect === "station_closure":
        return standardLayout(issue, remedy, effect, location)
      case (region === "boundary" || region === "here")
            && (effect === "shuttle" || effect === "suspension"):
        return standardLayout(issue, remedy, effect, location)
      case region === "outside" && endpoints && (effect === "shuttle" || effect === "suspension"):
        return downstreamLayout(endpoints, effect, remedy)
      default:
        return fallbackLayout(issue, remedy, effect, routes)
    }
  }

  return (
    <div className="pre-fare-alert__page">
      { !isMultiLine(effect, region) && <PreFareAlertBanner routes={routes} /> }
      <div
        className={classWithModifiers("alert-container", [
          "single-page",
          getAlertColor(routes)
        ])}
      >
        <div className="alert-card">
          <div className="alert-card__body">
            {layoutRenderer()}
          </div>
          <div className="alert-card__footer">
            { cause && <div className="alert-card__footer__cause">Cause: {formatCause(cause)}</div> }
            <div>Updated <span className="alert-card__footer__datetime">{updated_at}</span></div>
          </div>
        </div>
      </div>
    </div>
  );
};

const getRouteColor = (route: string) => {
  switch(route.substring(0, 2)) {
    case "rl": return "red"
    case "re": return "red"
    case "ol": return "orange"
    case "or": return "orange"
    case "bl": return "blue"
    case "gl": return "green"
    case "gr": return "green"
    default: return "yellow"
  }
}

// If only one route color is represented ("gl-union" and "gl-riverside" are the same route color)
// use that, otherwise "yellow"
const getAlertColor = (routes: string[]) => {
  const colors = routes.map(r => getRouteColor(r))
  const uniqueColors = new Set(colors).size
  return uniqueColors === 1 ? colors[0] : "yellow"
}

const PreFareAlertBanner: React.ComponentType<{routes: any[]}> = ({routes}) => {
  let banner;

  if (routes.length === 1 && ["rl", "ol", "bl", "gl", "gl-b", "gl-c", "gl-d", "gl-e"].includes(routes[0])) {
    // One destination, short text
    const route = routes[0]
    const LinePill = STRING_TO_SVG[route]
    const color = getRouteColor(route)

    banner = <div className={classWithModifiers("alert-banner", ["small", color])}>
      <span className="alert-banner__attention-text">ATTENTION</span>
      <LinePill className="alert-banner__route-pill--short" color={getHexColor(color)} />
      <span>riders</span>
    </div>
  } else if (routes.length === 1) {
    // One destination, long text
    const route = routes[0]
    const LinePill = STRING_TO_SVG[route]
    const color = getRouteColor(route)

    banner = <div className={classWithModifiers("alert-banner", ["large--one-route", color])}>
      <span><span className="alert-banner__attention-text">ATTENTION,</span> riders to</span>
      <LinePill className="alert-banner__route-pill--long"  color={getHexColor(color)} />
    </div>
  } else if (routes.length === 2) {
    // Two destinations
    banner = <div className={classWithModifiers("alert-banner", ["large--two-routes", getAlertColor(routes)])}>
      <span><span className="alert-banner__attention-text">ATTENTION,</span> riders to</span>
      {routes.map((route) => {
        const LinePill = STRING_TO_SVG[route]
        return <LinePill className="alert-banner__route-pill--long" color={getHexColor(getRouteColor(route))} />
      })}
    </div>
  } else {
    // Fallback
    banner = <div className={classWithModifiers("alert-banner", ["small", "yellow"])}>
      <span><span className="alert-banner__attention-text">ATTENTION,</span> riders</span>
    </div>
  }

  return banner;
}

export default PreFareSingleScreenAlert;
