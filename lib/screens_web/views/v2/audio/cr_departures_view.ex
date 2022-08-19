defmodule ScreensWeb.V2.Audio.CRDeparturesView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{departures: []}) do
    ~E|<p>There are no upcoming trips at this time</p>|
  end

  def render("_widget.ssml", %{departures: departures}) do
    ~E|<p>Upcoming trips:</p><%= Enum.map(departures, &render_departure/1) %>|
  end

  defp render_departure(_departure) do
    # %{
    #   headsign: headsign,
    #   time: time,
    #   track_number: track_number
    # } = departure

    ~E|<p>To be determined</p>|
  end

  # defp render_time_with_crowding({%{crowding: crowding, time: time}, 0}, route, headsign) do
  #   route_headsign_rendered = render_route_headsign(route, headsign)
  #   crowding_rendered = render_crowding_level(crowding)
  #   preposition = preposition_for_time_type(time.type)

  #   content =
  #     build_text([
  #       "The next",
  #       route_headsign_rendered,
  #       if(time_is_arr_brd?(time), do: nil, else: "arrives"),
  #       preposition,
  #       {time, &render_time/1},
  #       {crowding_rendered, fn c -> ~E|<break strength="medium"/> and <%= c %>| end}
  #     ])

  #   ~E|<s><%= content %></s>|
  # end

  # defp render_time_with_crowding({%{crowding: crowding, time: time}, _}, route, _headsign) do
  #   route_headsign_rendered = render_route_headsign(route, nil)
  #   crowding_rendered = render_crowding_level(crowding)
  #   preposition = preposition_for_time_type(time.type)

  #   prefix =
  #     case time.type do
  #       :timestamp -> "A later"
  #       _ -> "The following"
  #     end

  #   content =
  #     build_text([
  #       prefix,
  #       route_headsign_rendered,
  #       if(time_is_arr_brd?(time), do: nil, else: "arrives"),
  #       preposition,
  #       {time, &render_time/1},
  #       {crowding_rendered, fn c -> ~E|<break strength="medium"/> and <%= c %>| end}
  #     ])

  #   ~E|<s><%= content %></s>|
  # end

  # defp render_route_headsign(
  #        %{route_text: route_text, vehicle_type: vehicle_type, track_number: track_number},
  #        headsign
  #      ) do
  #   build_text([
  #     {route_text, &render_route/1},
  #     {vehicle_type || "trip", fn v -> ~E|<%= v %>| end},
  #     {headsign, fn h -> ~E|to <%= render_headsign(h) %>| end},
  #     {track_number, fn tn -> ~E|on track <%= tn %>| end}
  #   ])
  # end

  # defp render_route(route_text) do
  #   cond do
  #     String.contains?(route_text, "/") and match?([_, _], String.split(route_text, "/")) ->
  #       [part1, part2] = String.split(route_text, "/")

  #       ~E|<say-as interpret-as="address"><%= part1 %></say-as><say-as interpret-as="address"><%= part2 %></say-as>|

  #     match?({_bus_route, ""}, Integer.parse(route_text)) ->
  #       ~E|<say-as interpret-as="address"><%= route_text %></say-as>|

  #     true ->
  #       ~E|<%= route_text %>|
  #   end
  # end

  # defp render_headsign(%{headsign: headsign, variation: nil}) do
  #   ~E|<%= headsign %>|
  # end

  # defp render_headsign(%{headsign: headsign, variation: variation}) do
  #   ~E|<%= headsign %> <%= variation %>|
  # end

  # defp render_time(%{type: :text, text: "BRD"}), do: "is now boarding"
  # defp render_time(%{type: :text, text: "ARR"}), do: "is now arriving"
  # defp render_time(%{type: :text, text: "Now"}), do: "is now arriving"

  # defp render_time(%{type: :minutes, minutes: minute_diff}) do
  #   ~E|<%= minute_diff %> <%= pluralize_minutes(minute_diff) %>|
  # end

  # defp render_time(%{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm}) do
  #   minute_string = if minute < 10, do: "0#{minute}", else: "#{minute}"
  #   ~E|<%= hour %>:<%= minute_string %><%= am_pm %>|
  # end

  # defp pluralize_minutes(1), do: "minute"
  # defp pluralize_minutes(_), do: "minutes"

  # defp preposition_for_time_type(:text), do: nil
  # defp preposition_for_time_type(:minutes), do: "in"
  # defp preposition_for_time_type(:timestamp), do: "at"

  # defp render_crowding_level(1), do: "is currently not crowded"
  # defp render_crowding_level(2), do: "currently has some crowding"
  # defp render_crowding_level(3), do: "is currently crowded"
  # defp render_crowding_level(nil), do: nil

  # defp time_is_arr_brd?(time) do
  #   match?(%{type: :text}, time)
  # end

  # defp identity_render(value), do: ~E|<%= value %>|

  # defp build_text(value_renderers) do
  #   value_renderers
  #   |> Enum.reject(fn
  #     {value, renderer} when is_function(renderer) -> is_nil(value)
  #     value -> is_nil(value)
  #   end)
  #   |> Enum.map(fn
  #     {value, renderer} when is_function(renderer) -> renderer.(value)
  #     value -> identity_render(value)
  #   end)
  #   |> Enum.intersperse(~E| |)
  # end
end
