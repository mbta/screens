import useTextResizer from "Hooks/v2/use_text_resizer";
import React from "react";

import { classWithModifier, classWithModifiers, formatCause, imagePath } from "Util/util";

interface PreFareSingleScreenAlertProps {
  issue: string;
  location: string | null;
  cause: string;
  remedy: string;
  routes: string[];
  unaffected_routes: string[];
  effect: string;
  region: string;
  updated_at: string;
}

const doFallbackLayout = (issue: string | null, remedy: string | null, pioSecondaryTextSize: string) => ( 
  <>
    <img
      className="alert-card__pio-text__icon"
      src={imagePath("clock-negative.svg")}
    />
    {issue && <div className="alert-card__pio-text__main-text">{issue}</div>}
    {remedy && <div className={classWithModifier("alert-card__pio-text__secondary-text", pioSecondaryTextSize)}>{remedy}</div>}
  </>
)

const standardIssueSection = (issue: string, location: string | null, textSize: string) => (
  <div className="alert-card__issue">
    <img
      className="alert-card__icon"
      src={imagePath("no-service-black.svg")}
    />
    <div>
      <div className={classWithModifier("alert-card__content-block__text", textSize)}>
        {issue}
      </div>
      {location && <div className="alert-card__issue__location">{location}</div>}
    </div>
  </div>
)

const downstreamIssueSection = (issue: string) => (
  <div className="alert-card__issue">
    <div className={classWithModifier("alert-card__content-block__text", "medium")}>{issue}</div>
  </div>
)

const remedySection = (effect: string, remedy: string | null, contentTextSize: string) => (
  <div className="alert-card__remedy">
    { effect === "shuttle" ?
      <>
        <div className="alert-card__remedy__shuttle-icons">
          <img
            className="alert-card__icon"
            src={imagePath("bus-black.svg")}
          />
          <img
            className="alert-card__isa-icon"
            src={imagePath("ISA_Blue.svg")}
          /> 
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
        <img
          className="alert-card__icon"
          src={imagePath("nearby.svg")}
        />
        <div className="alert-card__remedy__text">{remedy}</div>
      </>
    }
  </div>
)

const mapSection = () => {
  <></>
}

const PreFareSingleScreenAlert: React.ComponentType<PreFareSingleScreenAlertProps> = (alert) => {
  const { cause, region, effect, issue, location, remedy, routes, unaffected_routes, updated_at } = alert;

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
        return fallbackLayout()
      case (effect === "station_closure" || effect === "stop_closure") && region === "here":
        return multiLineLayout()
      case effect === "station_closure" || effect === "stop_closure":
        return standardLayout()
      case (region === "boundary" || region === "here")
            && (effect === "shuttle" || effect === "suspension"):
        return standardLayout()
      case region === "outside" && (effect === "shuttle" || effect === "suspension"):
        return downstreamLayout()  
      default:
        return fallbackLayout()
    }
  }
  
  // For the standard layout, issue font can be medium or large. 
  // If remedy is "Seek alternate route", font size is static. Otherwise, it uses the same font size as
  // the issue.
  const standardLayout = () => {
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
  const downstreamLayout = () => (
    <div className={classWithModifier("alert-card__content-block", "downstream")}>
      {mapSection()}
      {downstreamIssueSection(issue)}
      {remedySection(effect, remedy, "medium")}
    </div>
  )

  // Covers the case where a station_closure only affects one line at a transfer station.
  // In the even rarer case that there are multiple branches in the routes list or unaffected routes list
  // the font size may need to shrink to accommodate.
  const multiLineLayout = () => {
    const { ref: contentBlockRef, size: contentTextSize } = useTextResizer({
      sizes: ["medium", "large"],
      maxHeight: 772,
      resetDependencies: [issue, remedy],
    });

    return (
      <div className="alert-card__content-block" ref={contentBlockRef}>
        <div className="alert-card__issue">
          <img
            className="alert-card__icon"
            src={imagePath("no-service-black.svg")}
          />
          <div className={classWithModifier("alert-card__content-block__text", contentTextSize)}>
            <img src={pillPath(routes[0])} className="alert-card__content-block__route-pill" />
            <span>trains are skipping this station</span>
          </div>
        </div>
        <div className="alert-card__issue">
          <img
            className="alert-card__icon"
            src={imagePath("info.svg")}
          />
          <div className={classWithModifier("alert-card__content-block__text", contentTextSize)}>
            {unaffected_routes.map(route => 
             <img src={pillPath(route)} key={route} className="alert-card__content-block__route-pill" />
            )}
           <span>trains stop as usual</span>
          </div>
        </div>
        {mapSection()}
      </div>
    )
  }

  const fallbackLayout = () => {
    // If there is more than 1 route in the banner, or the 1 route is longer than "GL·B"
    // the banner will be tall. Otherwise, it'll be 1-line
    const bannerHeight = (routes.length > 1 || routes[0].length > 4) ? 368 : 200

    const screenHeight = 1720, footerHeight = 84, bottomMargin = 32, alertCardPadding = 120 + 32

    const maxTextHeight = screenHeight - footerHeight - bottomMargin - alertCardPadding - bannerHeight

    const { ref: pioTextBlockRef, size: pioSecondaryTextSize } = useTextResizer({
      sizes: ["small", "medium"],
      maxHeight: maxTextHeight,
      resetDependencies: [issue, remedy],
    });

    return (
      <div className="alert-card__pio-text" ref={pioTextBlockRef}>
        {doFallbackLayout(issue, remedy, pioSecondaryTextSize)}
      </div>
    )
  }

  // TODO: When there is an SVG within the content-block, resize logic
  // doesn't kick in until the next data fetch. Should be fixed with better SVG loading

  return (
    <div className="pre-fare-alert__page">
      <PreFareAlertBanner routes={routes} />
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

const pillPath = (pillFilename: string) => imagePath(`pills/${pillFilename}.svg`);
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
const getAlertColor = (routes: string[]) => {
  const colors = routes.map(r => getRouteColor(r)).sort()
  return colors[0] === colors.slice(-1)[0] ? colors[0] : "yellow"
}

const PreFareAlertBanner: React.ComponentType<{routes: any[]}> = ({routes}) => {
  let banner;

  if (routes.length === 1 && ["red-line", "orange-line", "blue-line", "green-line", "gl-b", "gl-c", "gl-d", "gl-e"].includes(routes[0])) {
    // One destination, short text
    const route = routes[0]

    banner = <div className={classWithModifiers("alert-banner", ["small", getRouteColor(route)])}>
      <span className="alert-banner__attention-text">ATTENTION</span>
      <img src={pillPath(route)} className="alert-banner__route-pill--short" />
      <span>riders</span>
    </div>
  } else if (routes.length === 1) {
    // One destination, long text
    const route = routes[0]

    banner = <div className={classWithModifiers("alert-banner", ["large--one-route", getRouteColor(route)])}>
      <span><span className="alert-banner__attention-text">ATTENTION,</span> riders to</span>
      <img src={pillPath(route)} className="alert-banner__route-pill--long" />
    </div>
  } else if (routes.length === 2) {
    // Two destinations
    banner = <div className={classWithModifiers("alert-banner", ["large--two-routes", getAlertColor(routes)])}>
      <span><span className="alert-banner__attention-text">ATTENTION,</span> riders to</span>
      {routes.map((route) => (
        <img src={pillPath(route)} className="alert-banner__route-pill--long" />
      ))}
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
