defmodule ScreensWeb.AudioView do
  use ScreensWeb, :view

  import Phoenix.HTML

  @spec render_pill_header(atom(), String.t() | nil) :: Phoenix.HTML.safe()
  defp render_pill_header(pill, wayfinding) do
    ~E|<s><%= render_pill(pill) %> trips<%= render_wayfinding(wayfinding) %></s>
|
  end

  @spec render_pill(atom()) :: Phoenix.HTML.safe()
  defp render_pill(:blue), do: ~E"Blue Line"
  defp render_pill(:bus), do: ~E"Bus"
  defp render_pill(:cr), do: ~E"Commuter Rail"
  defp render_pill(:mattapan), do: ~E"Mattapan Line"
  defp render_pill(:orange), do: ~E"Orange Line"
  defp render_pill(:red), do: ~E"Red Line"
  defp render_pill(:silver), do: ~E"Silver Line"

  @spec render_pill_mode(atom(), non_neg_integer()) :: Phoenix.HTML.safe()
  defp render_pill_mode(pill, 1) when pill in ~w[blue orange red cr]a, do: ~E"train"
  defp render_pill_mode(pill, _) when pill in ~w[blue orange red cr]a, do: ~E"trains"
  defp render_pill_mode(pill, 1) when pill in ~w[bus silver]a, do: ~E"bus"
  defp render_pill_mode(pill, _) when pill in ~w[bus silver]a, do: ~E"buses"
  defp render_pill_mode(:mattapan, 1), do: ~E"trolley"
  defp render_pill_mode(:mattapan, _), do: ~E"trolleys"

  defp render_route_descriptor({route, route_id, destination}) do
    if route_id in ~w[Blue Red Mattapan Orange] or String.starts_with?(route_id, "CR") do
      ~E|<%= render_route_id(route_id) %> to <%= destination %>|
    else
      ~E|<%= render_route(route) %> to <%= destination %>|
    end
  end

  @spec render_route_id(String.t()) :: Phoenix.HTML.safe()
  defp render_route_id("CR-" <> line_name) do
    ~E|<%= line_name %> Line train|
  end

  defp render_route_id(color) when color in ~w[Blue Red Orange] do
    ~E|<%= color %> Line train|
  end

  defp render_route_id("Mattapan"), do: ~E"Mattapan Trolley"

  @spec render_route(String.t()) :: Phoenix.HTML.safe()
  defp render_route("SL" <> route_number) do
    ~E|Silver Line route <%= say_as_address(route_number) %>|
  end

  defp render_route(route) do
    route_number =
      if String.contains?(route, "/") do
        route
        |> String.split("/")
        |> Enum.map(&say_as_address/1)
      else
        say_as_address(route)
      end

    ~E|Route <%= route_number %>|
  end

  defp render_departure_groups([]) do
    ~E|<s>No departures currently available</s>
|
  end

  defp render_departure_groups(departure_groups) do
    departure_groups
    |> Enum.map(&render_departure_group/1)
    |> Enum.intersperse(~E|<break strength="x-strong"/>
|)
  end

  defp render_departure_group(
         {route_descriptor,
          %{
            times: time_groups,
            alerts: alerts,
            wayfinding: wayfinding,
            track_number: track_number
          }}
       ) do
    [first | rest] = time_groups

    first_rendered =
      render_first_departure_time_group(route_descriptor, track_number, wayfinding, first)

    rest_rendered = Enum.map(rest, &render_departure_time_group_with_prefix/1)

    alerts_rendered = render_alerts(alerts, route_descriptor)

    ~E|<%= first_rendered %><%= rest_rendered %><%= alerts_rendered %>|
  end

  defp render_first_departure_time_group(route_descriptor, track_number, wayfinding, time_group) do
    route_destination = render_route_descriptor(route_descriptor)

    track_number_rendered = render_track_number(track_number)

    wayfinding_rendered = render_wayfinding(wayfinding)

    times = render_departure_time_group(time_group)

    ~E|<s><%= route_destination %><%= track_number_rendered %><%= wayfinding_rendered %><%= times %></s>
|
  end

  defp render_departure_time_group_with_prefix(%{pill: pill, type: type, values: values}) do
    number = length(values)

    prefix =
      case type do
        :timestamp -> ~E|Later <%= render_pill_mode(pill, number) %>|
        _ -> ~E|Next <%= render_pill_mode(pill, number) %>|
      end

    time_group_rendered = render_departure_time_group(%{type: type, values: values})

    ~E|<s><%= prefix %> <%= time_group_rendered %></s>
|
  end

  defp render_departure_time_group(%{type: type, values: values}) do
    preposition = preposition_for(type)

    times = render_time_representations(type, values)

    ~E| <%= preposition %><%= times %>|
  end

  @spec preposition_for(atom()) :: Phoenix.HTML.safe()
  defp preposition_for(:text), do: ~E""
  defp preposition_for(:minutes), do: ~E"in "
  defp preposition_for(:timestamp), do: ~E"at "

  @spec render_time_representations(atom(), [any()]) :: [Phoenix.HTML.safe()]
  defp render_time_representations(type, values) do
    values
    |> Enum.map(&render_time_representation(%{type: type, value: &1}))
    |> oxford_comma_intersperse()
  end

  @spec render_time_representation(Screens.Audio.time_representation()) :: Phoenix.HTML.safe()
  defp render_time_representation(%{type: :text, value: :brd}), do: ~E"is now boarding"
  defp render_time_representation(%{type: :text, value: :arr}), do: ~E"is now arriving"

  defp render_time_representation(%{type: :minutes, value: minutes}) do
    ~E|<%= minutes %> <%= pluralize_minutes(minutes) %>|
  end

  defp render_time_representation(%{type: :timestamp, value: timestamp}) do
    ~E|<%= timestamp %>|
  end

  @spec render_alerts([atom()], Screens.Audio.departure_group_key()) :: [Phoenix.HTML.safe()]
  defp render_alerts(alerts, route_descriptor) do
    Enum.map(alerts, &render_alert(&1, route_descriptor))
  end

  defp render_alert(:delay, route_descriptor) do
    ~E|<s>There are delays on <%= render_route_descriptor(route_descriptor) %></s>
|
  end

  defp render_alert(_, _), do: ~E""

  defp render_wayfinding(nil), do: ~E""
  defp render_wayfinding(wayfinding), do: ~E| from <%= wayfinding %>|

  defp render_track_number(nil), do: ~E""
  defp render_track_number(track_number), do: ~E| on track <%= track_number %>|

  @spec render_psa({:plaintext | :ssml, String.t(), :takeover | :end} | nil) ::
          Phoenix.HTML.safe()
  defp render_psa(nil), do: ~E""

  defp render_psa({:plaintext, text, _}) do
    ~E|<p><s><%= text %></s></p>|
  end

  defp render_psa({:ssml, ssml, _}) do
    raw(ssml)
  end

  @spec say_as_address(Phoenix.HTML.unsafe()) :: Phoenix.HTML.safe()
  defp say_as_address(text) do
    ~E|<say-as interpret-as="address"><%= text %></say-as>|
  end

  defp pluralize_minutes(1), do: "minute"
  defp pluralize_minutes(_), do: "minutes"

  defp oxford_comma_intersperse(list), do: oxford_comma_intersperse(list, :start)

  defp oxford_comma_intersperse([], _state) do
    []
  end

  defp oxford_comma_intersperse([el], _state) do
    [el]
  end

  defp oxford_comma_intersperse([el1, el2], :start) do
    [el1, ~E" and ", el2]
  end

  defp oxford_comma_intersperse([el1, el2], :recurse) do
    [el1, ~E", and ", el2]
  end

  defp oxford_comma_intersperse([first | rest], _state) do
    [first, ~E", " | oxford_comma_intersperse(rest, :recurse)]
  end
end
