defmodule Screens.Facilities.Facility do
  alias Screens.Stops

  @type id :: String.t()

  @callback fetch_stop_for_facility(id()) :: {:ok, Stops.Stop.t()} | {:error, term()}
  def fetch_stop_for_facility(facility_id, get_json_fn \\ &Screens.V3Api.get_json/2) do
    case get_json_fn.("facilities/#{facility_id}", %{
           "include" => "stop"
         }) do
      {:ok, %{"data" => _data, "included" => [stop_map]}} ->
        {:ok, Stops.Parser.parse_stop(stop_map)}

      error ->
        {:error, error}
    end
  end
end
