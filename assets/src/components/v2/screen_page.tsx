import React from "react";
import { useParams } from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";
import { ScreenIDProvider } from "Hooks/v2/use_screen_id";
import { useQueryParams } from "Hooks/v2/use_query_params";

interface ScreenPageProps {
  id?: string;
  paramKeys?: string[];
}

const ScreenPage = ({ id, paramKeys }: ScreenPageProps) => {
  const screenId = id ?? (useParams() as { id: string }).id;

  const queryParams = useQueryParams(paramKeys ?? []);

  return (
    <ScreenIDProvider id={screenId}>
      <ScreenContainer id={screenId} queryParams={queryParams} />
    </ScreenIDProvider>
  );
};

export default ScreenPage;
