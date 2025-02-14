import React from "react";
import { useLocation, useParams } from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";
import { ScreenIDProvider } from "Hooks/v2/use_screen_id";

const getQueryParams = (paramKeys: string[] = []) => {
  const { search } = useLocation();
  const urlParams = new URLSearchParams(search);

  const paramMap = new Map<string, string>();
  paramKeys.forEach((key) => {
    const value = urlParams.get(key);
    if (value) {
      paramMap.set(key, value);
    }
  });
  return paramMap;
};

interface ScreenPageProps {
  id?: string;
  paramKeys?: string[];
}

const ScreenPage = ({ id, paramKeys }: ScreenPageProps) => {
  const screenId = id ?? (useParams() as { id: string }).id;

  const queryParams = paramKeys ? getQueryParams(paramKeys) : undefined;

  return (
    <ScreenIDProvider id={screenId}>
      <ScreenContainer id={screenId} queryParams={queryParams} />
    </ScreenIDProvider>
  );
};

export default ScreenPage;
