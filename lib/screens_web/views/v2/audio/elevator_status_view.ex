defmodule ScreensWeb.V2.Audio.ElevatorStatusView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        active_at_home_pages: active_at_home_pages,
        list_pages: list_pages,
        upcoming_at_home_pages: upcoming_at_home_pages,
        elsewhere_pages: elsewhere_pages
      }) do
    ~E|
    <p>Elevator Closures across the T.</p>
    <p><%= render_cta() %></p>
    <p><%= render_active_at_home(active_at_home_pages) %></p>
    <p>Other elevator closures:</p>
    <p><%= Enum.map(list_pages, &render_page/1) %></p>
    <p><%= Enum.map(upcoming_at_home_pages, &render_page/1) %></p>
    <p><%= Enum.map(elsewhere_pages, &render_page/1) %></p>
    <p><%= render_cta() %></p>
    |
  end

  defp render_cta do
    ~E|For a full list of elevator alerts, and directions to <w role="amazon:JJ">alternate</w> accessible paths, visit MBTA dot com slash: alerts: slash: access, or call <say-as interpret-as="telephone">617-222-2828</say-as>.|
  end

  defp render_active_at_home(pages) do
    if Enum.empty?(pages) do
      "All elevators are working at this station."
    else
      Enum.map(pages, &render_page/1)
    end
  end

  # Detail pages
  defp render_page(%{
         station: %{
           is_at_home_stop: is_at_home_stop,
           name: station_name,
           elevator_closures: [
             %{
               elevator_id: id,
               elevator_name: name,
               description: alternate_path_instructions,
               timeframe: %{happening_now: happening_now} = timeframe
             }
           ]
         }
       }) do
    station_text =
      if is_at_home_stop do
        "this station"
      else
        station_name
      end

    upcoming_text =
      if happening_now do
        ""
      else
        "Upcoming elevator closure:"
      end

    ~E|<s><%= upcoming_text %> At <%= station_text %>, <%= render_timeframe(timeframe) %>: Elevator Number <say-as interpret-as="telephone"><%= id %></say-as>, <%= name %>: <%= alternate_path_instructions %></s>|
  end

  # List pages
  defp render_page(%{stations: stations}) do
    Enum.map(stations, &render_list_page_station_row/1)
  end

  defp render_list_page_station_row(%{name: station_name, elevator_closures: elevator_closures}) do
    ~E|<%= Enum.map(elevator_closures, &render_list_page_elevator_row(&1, station_name)) %>|
  end

  defp render_list_page_elevator_row(%{elevator_id: id, elevator_name: name}, station_name) do
    ~E|<%= station_name %> Elevator Number <say-as interpret-as="telephone"><%= id %></say-as>: <%= name %> is closed.<break/>|
  end

  defp render_timeframe(%{happening_now: true, active_period: %{"end" => nil}}),
    do: ~E|Until further notice|

  defp render_timeframe(%{happening_now: true, active_period: %{"end" => end_dt_string}}) do
    {:ok, end_dt, _} = DateTime.from_iso8601(end_dt_string)
    ~E|Until <%= Calendar.strftime(end_dt, "%B %d") %>|
  end

  defp render_timeframe(%{
         happening_now: false,
         active_period: %{"start" => start_dt, "end" => end_dt}
       }) do
    ~E|<%= render_datetime(start_dt) %> through <%= render_datetime(end_dt) %>|
  end

  defp render_datetime(dt_string) do
    {:ok, dt, _} = DateTime.from_iso8601(dt_string)
    Calendar.strftime(dt, "%B %d")
  end
end
