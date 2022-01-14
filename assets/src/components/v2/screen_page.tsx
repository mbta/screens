import React from "react";
import { useParams } from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";
import useSentry from "Hooks/use_sentry";

const ScreenPage = () => {
  const { id } = useParams();
  useSentry();
  return <ScreenContainer id={id} />;
};

export default ScreenPage;
