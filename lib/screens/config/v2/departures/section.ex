defmodule Screens.Config.V2.Departures.Section do
  @moduledoc false

  alias Screens.Config.V2.Departures.{Filter, Headway, Query}

  @type t :: %__MODULE__{
          query: Query.t(),
          filter: Filter.t() | nil,
          headway: Headway.t()
        }

  @enforce_keys [:query]
  defstruct query: nil,
            filter: nil,
            headway: Headway.from_json(:default)

  use Screens.Config.Struct, children: [query: Query, filter: Filter, headway: Headway]

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
