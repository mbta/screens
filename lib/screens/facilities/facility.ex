defmodule Screens.Facilities.Facility do
  @moduledoc """
  Functions for fetching facility data from the V3 API.
  """

  alias Screens.Stops

  @type id :: String.t()

  @callback fetch_stop_for_facility(id()) :: {:ok, Stops.Stop.t()} | {:error, term()}
  def fetch_stop_for_facility(facility_id) do
    case Screens.V3Api.get_json("facilities/#{facility_id}", %{
           "include" => "stop"
         }) do
      {:ok, %{"data" => _data, "included" => [stop_map]}} ->
        {:ok, Stops.Parser.parse_stop(stop_map)}

      error ->
        {:error, error}
    end
  end
end
