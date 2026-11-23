defmodule Screens.Schedules.Dataset do
  @moduledoc """
  One immutable parsed Schedule and its source metadata, to be used for Schedule caching and access.

  Query coverage describes the complete service-date query.
  """

  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias ScreensConfig.Departures.Mode

  @type query_params :: %{
          optional(:direction_id) => Trip.direction(),
          optional(:mode) => Mode.t(),
          optional(:route_ids) => [Route.id()],
          optional(:route_type) => [RouteType.t()],
          optional(:sort) => String.t(),
          optional(:stop_ids) => [Stop.id()]
        }

  @type query_coverage :: %{required(:params) => query_params(), required(:complete?) => true}

  @enforce_keys [
    :schedules,
    :service_date,
    :query_coverage,
    :generation,
    :retrieved_at,
    :validated_at
  ]
  defstruct @enforce_keys ++ [last_modified: nil, source_version: nil]

  @type t :: %__MODULE__{
          schedules: [Screens.Schedules.Schedule.t()],
          service_date: Date.t(),
          query_coverage: query_coverage(),
          generation: reference(),
          retrieved_at: DateTime.t(),
          validated_at: DateTime.t(),
          last_modified: String.t() | nil,
          source_version: String.t() | nil
        }
end
