defmodule Screens.BlueBikes.Parser do
  @moduledoc """
  Parses station data from decoded JSON.
  """

  alias Screens.BlueBikes
  alias Screens.BlueBikes.Station

  @spec parse(map, map) :: {:ok, BlueBikes.t(), pos_integer(), pos_integer()} | :error
  def parse(station_information_json, station_status_json) do
    with {:ok, information, info_last_updated} <-
           parse_station_information(station_information_json),
         {:ok, status, status_last_updated} <- parse_station_status(station_status_json) do
      stations_by_id =
        information
        |> Map.merge(status, &merge_station_data_into_struct/3)
        # station_information.json and station_status.json should always contain matching
        # IDs, but in case they ever don't for some reason, this will remove entries missing
        # from one or the other.
        |> Map.filter(fn {_k, v} -> is_struct(v, Station) end)

      {:ok, %BlueBikes{stations_by_id: stations_by_id}, info_last_updated, status_last_updated}
    end
  end

  defp merge_station_data_into_struct(id, information, status)

  defp merge_station_data_into_struct(_id, information, %{station_status: "out_of_service"}) do
    %Station{name: information.name, status: :out_of_service}
  end

  defp merge_station_data_into_struct(_id, information, %{valet_active?: true}) do
    %Station{name: information.name, status: :valet}
  end

  defp merge_station_data_into_struct(_id, information, status) do
    %Station{
      name: information.name,
      status: {:normal, Map.take(status, [:num_docks_available, :num_bikes_available])}
    }
  end

  defp parse_station_information(%{
         "data" => %{"stations" => stations},
         "last_updated" => last_updated
       })
       when is_list(stations) do
    {:ok, Enum.into(stations, %{}, &parse_information_kv/1), last_updated}
  end

  defp parse_station_information(_), do: :error

  defp parse_station_status(%{"data" => %{"stations" => stations}, "last_updated" => last_updated})
       when is_list(stations) do
    {:ok, Enum.into(stations, %{}, &parse_status_kv/1), last_updated}
  end

  defp parse_information_kv(%{"station_id" => id, "name" => name}) do
    {id, %{name: name}}
  end

  defp parse_status_kv(status) do
    %{
      "station_id" => id,
      "num_bikes_available" => num_bikes_available,
      "num_docks_available" => num_docks_available,
      "station_status" => station_status
    } = status

    {id,
     %{
       num_bikes_available: num_bikes_available,
       num_docks_available: num_docks_available,
       station_status: station_status,
       valet_active?: get_in(status, ["valet", "active"]) == true
     }}
  end
end
