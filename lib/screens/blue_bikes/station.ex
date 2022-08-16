defmodule Screens.BlueBikes.Station do
  @moduledoc """
  Models one BlueBikes station's state.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          status: status
        }

  @type status ::
          {:normal, availability}
          | :out_of_service
          | :valet

  @type availability :: %{
          num_docks_available: non_neg_integer,
          num_bikes_available: non_neg_integer
        }

  @enforce_keys [:name, :status]
  defstruct @enforce_keys
end
