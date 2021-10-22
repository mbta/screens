defmodule ScreensWeb.V2.Audio.DeparturesView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{sections: []}) do
    ~E|<p>There are no upcoming trips at this time</p>|
  end

  def render("_widget.ssml", %{sections: sections}) do
    if Enum.all?(sections, &match?(%{type: :normal_section, departure_groups: []}, &1)) do
      ~E|<p>There are no upcoming trips at this time</p>|
    else
      ~E|<p>Upcoming trips:</p><%= Enum.map(sections, &render_section/1) %>|
    end
  end

  defp render_section(%{type: :notice_section, text: text}) do
    ~E|<p><%= text %></p>|
  end

  defp render_section(%{type: :normal_section, departure_groups: departure_groups}) do
    ~E|<p><%= Enum.map(departure_groups, &render_departure_group/1) %></p>|
  end

  defp render_departure_group({:notice, text}) do
    ~E|<s><%= text %></s>|
  end

  defp render_departure_group({:normal, departures_group}) do
    %{
      route: route,
      headsign: headsign,
      time_groups_with_crowding: time_groups_with_crowding
    } = departures_group

    route_headsign_rendered = render_route_headsign(route, headsign)

    time_groups_with_crowding_rendered =
      render_time_groups_with_crowding(time_groups_with_crowding, route.vehicle_type)

    if first_group_is_arr_brd?(time_groups_with_crowding) do
      # time readout starts with "is now arriving/boarding", no connecting verb needed
      ~E|<s><%= route_headsign_rendered %> <%= time_groups_with_crowding_rendered %></s>|
    else
      ~E|<s><%= route_headsign_rendered %> arrives <%= time_groups_with_crowding_rendered %></s>|
    end
  end

  defp render_route_headsign(
         %{route_text: route_text, vehicle_type: vehicle_type, track_number: track_number},
         headsign
       ) do
    build_route_headsign([
      {:route, route_text},
      {:vehicle, vehicle_type},
      {:headsign, headsign},
      {:track, track_number}
    ])
  end

  defp build_route_headsign(stages, acc \\ "The next")

  defp build_route_headsign([], acc), do: acc

  defp build_route_headsign([{_stage, nil} | rest], acc) do
    build_route_headsign(rest, acc)
  end

  defp build_route_headsign([{:route, route_text} | rest], acc) do
    route_rendered =
      cond do
        String.contains?(route_text, "/") and match?([_, _], String.split(route_text, "/")) ->
          [part1, part2] = String.split(route_text, "/")

          ~E|<%= acc %> <say-as interpret-as="address"><%= part1 %></say-as><say-as interpret-as="address"><%= part2 %></say-as>|

        match?({_bus_route, ""}, Integer.parse(route_text)) ->
          ~E|<%= acc %> <say-as interpret-as="address"><%= route_text %></say-as>|

        true ->
          ~E|<%= acc %> <%= route_text %>|
      end

    build_route_headsign(rest, route_rendered)
  end

  defp build_route_headsign([{:vehicle, vehicle_type} | rest], acc) do
    build_route_headsign(rest, ~E|<%= acc %> <%= vehicle_type %>|)
  end

  defp build_route_headsign([{:headsign, headsign} | rest], acc) do
    build_route_headsign(rest, ~E|<%= acc %> to <%= render_headsign(headsign) %>|)
  end

  defp build_route_headsign([{:track, track_number} | rest], acc) do
    build_route_headsign(rest, ~E|<%= acc %> on track <%= track_number %>|)
  end

  defp render_headsign(%{headsign: headsign, variation: nil}) do
    ~E|<%= headsign %>|
  end

  defp render_headsign(%{headsign: headsign, variation: variation}) do
    ~E|<%= headsign %> <%= variation %>|
  end

  defp render_time_groups_with_crowding(time_groups_with_crowding, vehicle_type) do
    time_groups_with_crowding
    |> Enum.with_index()
    |> Enum.map(&render_time_group_with_crowding(&1, vehicle_type))
  end

  defp render_time_group_with_crowding({{type, times_with_crowding}, 0}, _) do
    rendered =
      times_with_crowding
      |> Enum.map(&render_time_with_crowding/1)
      |> oxford_comma_intersperse()

    preposition = preposition_for_time_type(type)

    if is_nil(preposition) do
      rendered
    else
      ~E|<%= preposition %> <%= rendered %>|
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp render_time_group_with_crowding({{type, times_with_crowding}, _}, vehicle_type) do
    times_with_crowding_rendered =
      times_with_crowding
      |> Enum.map(&render_time_with_crowding/1)
      |> oxford_comma_intersperse()

    prefix =
      case type do
        :timestamp -> "Later"
        _ -> "Following"
      end

    vehicle =
      case {vehicle_type, length(times_with_crowding)} do
        {nil, 1} -> "trip"
        {nil, _} -> "trips"
        {v, 1} -> v
        {:train, _} -> "trains"
        {:bus, _} -> "buses"
        {:trolley, _} -> "trolleys"
        {:ferry, _} -> "ferries"
      end

    preposition = preposition_for_time_type(type)

    if is_nil(preposition) do
      ~E|</s><s><%= prefix %> <%= vehicle %> <%= times_with_crowding_rendered %>|
    else
      ~E|</s><s><%= prefix %> <%= vehicle %> <%= preposition %> <%= times_with_crowding_rendered %>|
    end
  end

  defp render_time_with_crowding(%{crowding: crowding, time: time}) do
    time_rendered = render_time(time)
    crowding_rendered = render_crowding_level(crowding)

    rendered = time_rendered

    if is_nil(crowding_rendered) do
      rendered
    else
      ~E|<%= rendered %> <%= crowding_rendered %>|
    end
  end

  defp render_time(%{type: :text, text: "BRD"}), do: "is now boarding"
  defp render_time(%{type: :text, text: "ARR"}), do: "is now arriving"
  defp render_time(%{type: :text, text: "Now"}), do: "is now arriving"

  defp render_time(%{type: :minutes, minutes: minute_diff}) do
    ~E|<%= minute_diff %> <%= pluralize_minutes(minute_diff) %>|
  end

  defp render_time(%{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm}) do
    minute_string = if minute < 10, do: "0#{minute}", else: "#{minute}"
    ~E|<%= hour %>:<%= minute_string %><%= am_pm %>|
  end

  defp pluralize_minutes(1), do: "minute"
  defp pluralize_minutes(_), do: "minutes"

  defp preposition_for_time_type(:text), do: nil
  defp preposition_for_time_type(:minutes), do: "in"
  defp preposition_for_time_type(:timestamp), do: "at"

  defp render_crowding_level(1), do: "(currently not crowded)"
  defp render_crowding_level(2), do: "(currently with some crowding)"
  defp render_crowding_level(3), do: "(currently crowded)"
  defp render_crowding_level(nil), do: nil

  defp oxford_comma_intersperse(list, state \\ :start)

  defp oxford_comma_intersperse([], _state) do
    []
  end

  defp oxford_comma_intersperse([el], _state) do
    [el]
  end

  defp oxford_comma_intersperse([el1, el2], :start) do
    [el1, " and ", el2]
  end

  defp oxford_comma_intersperse([el1, el2], :recurse) do
    [el1, ", and ", el2]
  end

  defp oxford_comma_intersperse([first | rest], _state) do
    [first, ", " | oxford_comma_intersperse(rest, :recurse)]
  end

  defp first_group_is_arr_brd?(time_groups_with_crowding) do
    match?([{:text, _} | _], time_groups_with_crowding)
  end
end
