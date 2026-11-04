defmodule Screens.Schedules.Dataset do
  @moduledoc """
  One immutable parsed schedule acquisition and its source metadata.

  Coverage describes the complete service-date query, not independently verified
  station mappings or headway windows. A successful empty list is known empty
  coverage. The HTTP validator is not a published schedule version.
  """

  @enforce_keys [:schedules, :service_date, :coverage, :generation, :retrieved_at, :validated_at]
  defstruct @enforce_keys ++ [last_modified: nil, source_version: nil]

  @type t :: %__MODULE__{
          schedules: [Screens.Schedules.Schedule.t()],
          service_date: Date.t(),
          coverage: map(),
          generation: reference(),
          retrieved_at: DateTime.t(),
          validated_at: DateTime.t(),
          last_modified: String.t() | nil,
          source_version: String.t() | nil
        }
end
