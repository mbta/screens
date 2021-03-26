import React from "react";
import { useParams } from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";

const ScreenPage = () => {
  const { id } = useParams();
  return <ScreenContainer id={id} />;
};

export default ScreenPage;
