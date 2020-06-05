defmodule ScreensWeb.AudioView do
  use ScreensWeb, :view

  alias Phoenix.HTML

  @type time_representation :: :brd | :arr | {:minutes, integer} | {:timestamp, String.t()}

  def render_route(route, route_id, destination) do
    if route_id in ~w[Blue Red Mattapan Orange] or String.starts_with?(route_id, "CR") do
      render("_train_route.ssml",
        route_id: route_id,
        destination: destination
      )
    else
      render("_bus_route.ssml", route: route, destination: destination)
    end
  end

  def render_time(departure_time, current_time, vehicle_status, stop_type) do
    time = get_time_representation(departure_time, current_time, vehicle_status, stop_type)
    render_time_representation(time)
  end

  @spec render_route_id(String.t()) :: HTML.unsafe()
  def render_route_id("CR-" <> line_name) do
    [line_name, " Commuter Rail train"]
  end

  def render_route_id(color) when color in ~w[Blue Red Orange] do
    [color, " Line train"]
  end

  def render_route_id("Mattapan"), do: "Mattapan Trolley"

  @spec render_route(String.t()) :: HTML.unsafe()
  def render_route("SL" <> route_number) do
    ["Silver Line route ", say_as_address_open(), route_number, say_as_close()]
  end

  def render_route(route) do
    if String.contains?(route, "/") do
      for route_part <- String.split(route, "/") do
        [say_as_address_open(), route_part, say_as_close()]
      end
    else
      [say_as_address_open(), route, say_as_close()]
    end
  end

  @spec render_time_representation(time_representation) :: HTML.unsafe()
  def render_time_representation(:brd), do: "is now boarding"
  def render_time_representation(:arr), do: "is now arriving"

  def render_time_representation({:minutes, minutes}) do
    ["departs in ", Integer.to_string(minutes), " minutes"]
  end

  def render_time_representation({:timestamp, timestamp}) do
    ["departs at ", timestamp]
  end

  @spec say_as_address_open() :: HTML.safe()
  defp say_as_address_open, do: {:safe, ~s|<say-as interpret-as="address">|}

  @spec say_as_close() :: HTML.safe()
  defp say_as_close, do: {:safe, "</say-as>"}

  defp get_time_representation(departure_time, current_time, vehicle_status, stop_type) do
    {:ok, departure_time, _} = DateTime.from_iso8601(departure_time)
    {:ok, current_time, _} = DateTime.from_iso8601(current_time)

    second_difference = DateTime.diff(departure_time, current_time)
    minute_difference = round(second_difference / 60)

    cond do
      vehicle_status === :stopped_at and second_difference <= 90 ->
        :brd

      second_difference <= 30 ->
        if stop_type === :first_stop, do: :brd, else: :arr

      minute_difference < 60 ->
        {:minutes, minute_difference}

      true ->
        timestamp =
          departure_time
          |> Timex.to_datetime("America/New_York")
          |> Timex.format!("{h12}:{m} {AM}")

        {:timestamp, timestamp}
    end
  end
end
