import React from "react";
import { useParams } from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";

const ScreenPage = ({ WidgetComponent }) => {
  const { id } = useParams();
  return <ScreenContainer id={id} WidgetComponent={WidgetComponent} />;
};

export default ScreenPage;
