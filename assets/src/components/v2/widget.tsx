import React from "react";

import Alert from "Components/v2/alert";
import NoDataDepartures from "Components/v2/departures/no_data";
import Normal from "Components/v2/screen/normal";
import NormalDepartures from "Components/v2/departures/normal";
import NormalFooter from "Components/v2/footer/normal";
import NormalHeader from "Components/v2/header/normal";
import OneLarge from "Components/v2/flex/one_large";
import OneMediumTwoSmall from "Components/v2/flex/one_medium_two_small";
import StaticImage from "Components/v2/static_image";
import Takeover from "Components/v2/screen/takeover";
import TwoMedium from "Components/v2/flex/two_medium";

const TYPE_TO_COMPONENT: Record<string, React.ComponentType<any>> = {
  alert: Alert,
  departures_no_data: NoDataDepartures,
  departures: NormalDepartures,
  normal_footer: NormalFooter,
  normal_header: NormalHeader,
  normal: Normal,
  one_large: OneLarge,
  one_medium_two_small: OneMediumTwoSmall,
  static_image: StaticImage,
  takeover: Takeover,
  two_medium: TwoMedium,
};

type WidgetData = { type: string } & Record<string, any>;

interface Props {
  data: WidgetData;
}

const Widget: React.ComponentType<Props> = ({ data }) => {
  const { type, ...props } = data;
  const Component = TYPE_TO_COMPONENT[type];

  if (Component) {
    return <Component {...props} />;
  }

  return <>{type}</>;
};

export default Widget;
export { WidgetData };
