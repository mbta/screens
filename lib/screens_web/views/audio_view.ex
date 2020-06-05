defmodule ScreensWeb.AudioView do
  use ScreensWeb, :view

  def render_route(route, route_id, destination) do
    if route_id in ~w[Blue Red Mattapan Orange] or String.starts_with?(route_id, "CR") do
      render("_train_route.ssml", route_id: route_id, destination: destination)
    else
      render("_bus_route.ssml", route: route, destination: destination)
    end
  end

  def render_time(departure_time, current_time, vehicle_status, stop_type) do
    {:ok, departure_time, _} = DateTime.from_iso8601(departure_time)
    {:ok, current_time, _} = DateTime.from_iso8601(current_time)

    second_difference = DateTime.diff(departure_time, current_time)
    minute_difference = round(second_difference / 60)

    time_representation =
      cond do
        vehicle_status === :stopped_at and second_difference <= 90 -> :brd
        second_difference <= 30 -> if stop_type === :first_stop, do: :brd, else: :arr
        minute_difference < 60 -> {:minutes, minute_difference}
        true -> {:timestamp, Timex.format!(departure_time, "{h12}:{m} {AM}")}
      end

    render("_time_representation.ssml", time_representation: time_representation)
  end
end
