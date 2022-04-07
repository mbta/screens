import React from "react";

import { classWithModifiers, imagePath } from "Util/util";
import FreeText from "./free_text";

interface ReconAlertProps {
  issue: string | any, // shouldn't be "any"
  location: string,
  cause: string,
  remedy: string,
  routes: any[], // shouldn't be "any"
  effect: string,
  urgent: boolean
}

const ReconstructedTakeover: React.ComponentType<ReconAlertProps> = (alert) => {
  const {cause, effect, issue, location, remedy, routes} = alert

  console.log('issue', issue)
  return (
    <>
      <div className={classWithModifiers("alert-container", ["takeover", "urgent", routes.length > 1 ? "yellow" : routes[0].color])}>
        <div className="alert-card alert-card--left">
          <div className="alert-card__body">
            <img
              className="alert-card__body__icon"
              src={imagePath("no-service-white.svg")}
            />
            <div className="x-large-text">
              {issue.text ? <FreeText elements={issue.text} /> : issue}
            </div>
            <div className="alert-card__body__location medium-text">{location}</div>
            <div className="alert-card__body__cause medium-text">{cause}</div>
          </div>
          <div className="alert-card__footer">
            <img
              className="alert-card__footer__t-icon"
              src={imagePath("logo-white.svg")}
            />
          </div>
        </div>
      </div>
      <div className={classWithModifiers("alert-container", ["takeover", "right", "urgent", routes.length > 1 ? "yellow" : routes[0].color])}>
        <div className="alert-card">
          <div className="alert-card__body">
            {effect==="shuttle" ?
              <>
                <img
                  className="alert-card__body__icon"
                  src={imagePath("bus-negative-white.svg")}
                />
                <div className="x-large-text">
                  {remedy}
                </div>
                <div className="alert-card__body__accessibility-info">
                  <img
                    className="alert-card__body__isa-icon"
                    src={imagePath("ISA_Blue.svg")}
                  />
                  <div className="alert-card__body__accessibility-info--text small-text">
                    All shuttle buses are accessible
                  </div>
                </div>
              </>
              : <div className="alert-card__body__remedy large-text">{remedy}</div>
            }
          </div>
          <div className="alert-card__footer">
            <div className="alert-card__footer__alerts-url">mbta.com/alerts</div>  
          </div>
        </div>
      </div>
    </>
    
  )
};

export default ReconstructedTakeover;
export { ReconAlertProps };
