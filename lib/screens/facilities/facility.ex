defmodule Screens.Facilities.Facility do
  @moduledoc """
  Functions for fetching facility data from the V3 API.
  """

  alias Screens.Facilities.Parser
  alias Screens.Stops.Stop
  alias Screens.V3Api

  @type id :: String.t()

  @type type ::
          :bike_storage
          | :bridge_plate
          | :electric_car_chargers
          | :elevated_subplatform
          | :elevator
          | :escalator
          | :fare_media_assistance_facility
          | :fare_media_assistant
          | :fare_vending_machine
          | :fare_vending_retailer
          | :fully_elevated_platform
          | :other
          | :parking_area
          | :pick_drop
          | :portable_boarding_lift
          | :ramp
          | :taxi_stand
          | :ticket_window

  @type t :: %__MODULE__{
          id: id(),
          excludes_stop_ids: [Stop.id()],
          latitude: float() | nil,
          longitude: float() | nil,
          long_name: String.t(),
          short_name: String.t(),
          stop: Stop.t() | :unloaded,
          type: type()
        }

  @type params :: [stop_ids: [Stop.id()], types: [type()]]

  @enforce_keys ~w[id long_name short_name stop type]a
  defstruct @enforce_keys ++ [excludes_stop_ids: [], latitude: nil, longitude: nil]

  @callback fetch(params()) :: {:ok, [t()]} | :error
  def fetch(params, get_json_fn \\ &V3Api.get_json/2) do
    encoded_params =
      params |> Enum.map(&encode_param/1) |> Map.new() |> Map.put("include", "stop")

    case get_json_fn.("facilities", encoded_params) do
      {:ok, response} -> {:ok, Parser.parse(response)}
      _ -> :error
    end
  end

  defp encode_param({:stop_ids, ids}), do: {"filter[stop]", Enum.join(ids, ",")}

  defp encode_param({:types, types}) do
    {
      "filter[type]",
      Enum.map_join(types, ",", fn type -> type |> to_string() |> String.upcase() end)
    }
  end

  @callback fetch_by_id(id()) :: {:ok, Stop.t()} | :error
  def fetch_by_id(id, get_json_fn \\ &V3Api.get_json/2) do
    case get_json_fn.("facilities/#{id}", %{"include" => "stop"}) do
      {:ok, response} -> {:ok, Parser.parse(response)}
      _ -> :error
    end
  end
end
