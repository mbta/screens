import useTextResizer from "Hooks/v2/use_text_resizer";
import React from "react";

import { classWithModifier, classWithModifiers, formatCause, imagePath } from "Util/util";

interface PreFareSingleScreenAlertProps {
  issue: string;
  location: string | null;
  cause: string;
  remedy: string;
  routes: string[];
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

const issueSection = (issue: string, location: string | null, textSize: string) => (
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

const buildRemedySection = (effect: string, remedy: string | null, contentTextSize: string) => (
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

const buildMapSection = () => {
  <></>
}

const PreFareSingleScreenAlert: React.ComponentType<PreFareSingleScreenAlertProps> = (alert) => {
  const { cause, region, effect, issue, location, remedy, routes, updated_at } = alert;

  console.log(alert)

  const layoutRenderer = () => {
    switch(true) {
      case effect === "delay":
        return fallbackLayout()
      case effect === "station_closure" || region === "here":
        return multiLineLayout()
      case effect === "station_closure":
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

  const standardLayout = () => {
    const { ref: contentBlockRef, size: contentTextSize } = useTextResizer({
      sizes: ["medium", "large"],
      maxHeight: 772,
      resetDependencies: [issue, remedy],
    });

    return (
      <div className="alert-card__content-block" ref={contentBlockRef}>
        {issueSection(issue, location, contentTextSize)}
        {buildRemedySection(effect, remedy, contentTextSize)}
        {buildMapSection()}
      </div>
    )
  }

  const multiLineLayout = () => {
    return (
      <div className="alert-card__content-block">
        {issueSection(issue, location, "large")}
        {buildRemedySection(effect, remedy, "large")}
        {buildMapSection()}
      </div>
    )
  }

  const downstreamLayout = () => (
    <div className={classWithModifier("alert-card__content-block", "downstream")}>
      {buildMapSection()}
      {downstreamIssueSection(issue)}
      {buildRemedySection(effect, remedy, "medium")}
    </div>
  )

  // Not sure this resizing logic is working correctly
  const fallbackLayout = () => {
    // If there is more than 1 route in the banner, or the 1 route is longer than "GL·B"
    // the banner will be tall. Otherwise, it'll be 1-line
    const bannerHeight = (routes.length > 1 || routes[0].length > 4) ? 368 : 200

    const screenHeight = 1720, footerHeight = 84, bottomMargin = 32, alertCardPadding = 120 + 32

    const maxTextHeight = screenHeight - footerHeight - bottomMargin - alertCardPadding - bannerHeight

    const { ref: pioTextBlockRef, size: pioSecondaryTextSize } = useTextResizer({
      sizes: ["small", "medium"],
      maxHeight: maxTextHeight,
      resetDependencies: [remedy],
    });

    return (
      <div className="alert-card__pio-text" ref={pioTextBlockRef}>
        {doFallbackLayout(issue, remedy, pioSecondaryTextSize)}
      </div>
    )
  }

  return (
    <div className="pre-fare-alert__page">
      <PreFareAlertBanner routes={routes} />
      <div
        className={classWithModifiers("alert-container", [
          "takeover",
          getAlertColor(routes)
        ])}
      >
        <div className="alert-card">
          <div className="alert-card__body">
            {layoutRenderer()}
          </div>
          <div className="alert-card__footer">
            <div className="alert-card__footer__cause">Cause: {formatCause(cause)}</div>
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
