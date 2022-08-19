defmodule ScreensWeb.V2.Audio.BlueBikesView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        destination: destination,
        minutes_range_to_destination: minutes_range_to_destination,
        stations: stations
      }) do
    stations = Enum.reject(stations, &(&1.status == :out_of_service))

    ~E|
    <%= render_stations(stations) %>
    <p>
      <s>It's a <%= minutes_range_to_destination %> minute bike ride to <%= destination %></s>
      <s>Free passes are available</s>
    </p>
    |
  end

  defp render_stations([station1, station2]) do
    ~E|
    <p>
      <s>A nearby <%= render_station(station1) %></s>
      <s>Another <%= render_station(station2) %></s>
    </p>
    |
  end

  defp render_stations([station]) do
    ~E|<p><s>A nearby <%= render_station(station) %></s></p>|
  end

  defp render_stations([]), do: ~E""

  defp render_station(%{status: :normal} = station) do
    ~E|Blue Bikes station is a <%= station.walk_distance_minutes %>-minute walk, or <%= station.walk_distance_feet %> feet away, with <%= station.num_bikes_available %> bikes and <%= station.num_docks_available %> docks|
  end

  defp render_station(%{status: :valet} = station) do
    ~E|Blue Bikes station is a <%= station.walk_distance_minutes %>-minute walk, or <%= station.walk_distance_feet %> feet away, with unlimited bikes available|
  end
end
