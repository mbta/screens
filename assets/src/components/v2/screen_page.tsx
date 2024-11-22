import React, { Fragment } from "react";
import { useParams } from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";
import { ScreenIDProvider } from "Hooks/v2/use_screen_id";
import WidgetTreeErrorBoundary from "Components/v2/widget_tree_error_boundary";
import { isDup } from "Util/outfront";

interface Props {
  id?: string;
}

const ScreenPage = ({ id }: Props) => {
  const screenId = id ?? (useParams() as { id: string }).id;
  const ErrorBoundaryOrFragment = isDup() ? Fragment : WidgetTreeErrorBoundary;

  return (
    <ScreenIDProvider id={screenId}>
      <ErrorBoundaryOrFragment>
        <ScreenContainer id={screenId} />
      </ErrorBoundaryOrFragment>
    </ScreenIDProvider>
  );
};

export default ScreenPage;
