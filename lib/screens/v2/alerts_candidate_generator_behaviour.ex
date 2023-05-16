defmodule Screens.V2.AlertsCandidateGeneratorBehaviour do
  alias Screens.Alerts.Alert

  @moduledoc """
  Behavior for fetching and filtering alerts in a CandidateGenerator.

  - `fetch(opts, fetch_alerts_fn)` is called to fetch alerts.
  - `relevant_alerts(alerts, config, opts)` filters the list of alerts.
  """

  # Parameters
  @type opts :: keyword()
  @type fetch_alerts_fn :: fun()
  @type config :: Screens.Config.Screen.t()

  # Returns
  @type alerts :: list(Alert.t())
  @type facilities :: map()

  @doc """
  Fetches a list of alerts using the function provided in parameters.
  """
  @callback fetch(opts(), fetch_alerts_fn()) :: {:ok, alerts()}

  @doc """
  Filters alerts so only relevant alerts are considered when creating a WidgetInstance struct.
  """
  @callback relevant_alerts(alerts(), config(), opts()) :: alerts()
end
