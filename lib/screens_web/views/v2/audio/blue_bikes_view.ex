defmodule ScreensWeb.V2.Audio.BlueBikesView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        destination: destination,
        minutes_range_to_destination: minutes_range_to_destination,
        stations: stations
      }) do
    ~E|
    <p>Nearby Blue Bikes stations.</p>
    <p>It's about a <%= minutes_range_to_destination %> minute bike ride to <%= destination %></p>
    <p><%= Enum.map(stations, &render_station/1) %></p>
    |
  end

  defp render_station(%{status: :normal} = station) do
    ~E|
    <s>The bike station at <%= station.name %> is a <%= station.walk_distance_minutes %> minute walk from here</s>
    <s>It currently has <%= station.num_bikes_available %> bikes available, and <%= station.num_docks_available %> docks available</s>
    |
  end

  defp render_station(%{status: :valet} = station) do
    ~E|
    <s>The bike station at <%= station.name %> is a <%= station.walk_distance_minutes %> minute walk from here</s>
    <s>It currently has valet service, with unlimited bikes available</s>
    |
  end

  defp render_station(%{status: :out_of_service} = station) do
    ~E|
    <s>The bike station at <%= station.name %> is currently not in service</s>
    |
  end
end
