import React from "react";
import { useParams } from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";

interface Props {
  id?: string;
}

const ScreenPage = ({ id }: Props) => {
  const screenId = id ?? (useParams() as { id: string }).id;
  return <ScreenContainer id={screenId} />;
};

export default ScreenPage;
