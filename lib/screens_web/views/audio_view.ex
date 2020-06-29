defmodule ScreensWeb.AudioView do
  use ScreensWeb, :view

  import Phoenix.HTML

  @spec render_pill_header(atom()) :: Phoenix.HTML.safe()
  def render_pill_header(:blue), do: ~E"Blue Line"
  def render_pill_header(:bus), do: ~E"Bus"
  def render_pill_header(:cr), do: ~E"Commuter Rail"
  def render_pill_header(:mattapan), do: ~E"Mattapan Line"
  def render_pill_header(:orange), do: ~E"Orange Line"
  def render_pill_header(:red), do: ~E"Red Line"
  def render_pill_header(:silver), do: ~E"Silver Line"

  @spec render_pill_mode(atom(), non_neg_integer()) :: Phoenix.HTML.safe()
  def render_pill_mode(pill, 1) when pill in ~w[blue orange red cr]a, do: ~E"train"
  def render_pill_mode(pill, _) when pill in ~w[blue orange red cr]a, do: ~E"trains"
  def render_pill_mode(pill, 1) when pill in ~w[bus silver]a, do: ~E"bus"
  def render_pill_mode(pill, _) when pill in ~w[bus silver]a, do: ~E"buses"
  def render_pill_mode(:mattapan, 1), do: ~E"trolley"
  def render_pill_mode(:mattapan, _), do: ~E"trolleys"

  def render_route_descriptor({route, route_id, destination}) do
    if route_id in ~w[Blue Red Mattapan Orange] or String.starts_with?(route_id, "CR") do
      render("_train_route.ssml",
        route_id: route_id,
        destination: destination
      )
    else
      render("_bus_route.ssml", route: route, destination: destination)
    end
  end

  @spec render_route_id(String.t()) :: Phoenix.HTML.safe()
  def render_route_id("CR-" <> line_name) do
    ~E|<%= line_name %> Line train|
  end

  def render_route_id(color) when color in ~w[Blue Red Orange] do
    ~E|<%= color %> Line train|
  end

  def render_route_id("Mattapan"), do: ~E"Mattapan Trolley"

  @spec render_route(String.t()) :: Phoenix.HTML.safe()
  def render_route("SL" <> route_number) do
    ~E|Silver Line route <%= say_as_address(route_number) %>|
  end

  def render_route(route) do
    route_number =
      if String.contains?(route, "/") do
        route
        |> String.split("/")
        |> Enum.map(&say_as_address/1)
      else
        say_as_address(route)
      end

    ~E|Bus <%= route_number %>|
  end

  def render_departure_groups([]) do
    ~E|<s>No departures currently available</s>
|
  end

  def render_departure_groups(departure_groups) do
    Enum.map(departure_groups, &render_departure_group/1)
    |> Enum.intersperse(~E|<break strength="x-strong"/>
|)
  end

  def render_departure_group({route_descriptor, %{times: time_groups, alerts: alerts}}) do
    [first | rest] = time_groups

    first_rendered = render_first_departure_time_group(route_descriptor, first)

    rest_rendered = Enum.map(rest, &render_departure_time_group(&1, true))

    alerts_rendered = render_alerts(alerts, route_descriptor)

    ~E|<%= first_rendered %><%= rest_rendered %><%= alerts_rendered %>|
  end

  defp render_first_departure_time_group(route_descriptor, time_group) do
    route_destination = render_route_descriptor(route_descriptor)

    times = render_departure_time_group(time_group, false)

    ~E|<s><%= route_destination %> <%= times %></s>
|
  end

  defp render_departure_time_group(%{pill: pill, type: type, values: values}, with_prefix) do
    number = length(values)

    prefix =
      cond do
        not with_prefix -> nil
        with_prefix and type == :minutes -> ~E|Next <%= render_pill_mode(pill, number) %>|
        with_prefix and type == :timestamp -> ~E|Later <%= render_pill_mode(pill, number) %>|
      end

    preposition =
      case type do
        :minutes -> ~E"in"
        :timestamp -> ~E"at"
      end

    times =
      values
      |> Enum.map(&render_time_representation(%{type: type, value: &1}))
      |> Enum.intersperse(", ")

    if with_prefix do
      ~E|<s><%= prefix %> <%= preposition %> <%= times %></s>
|
    else
      ~E|<%= preposition %> <%= times %>|
    end
  end

  defp render_departure_time_group(%{pill: pill, type: :text, value: value}, true) do
    ~E|Next <%= render_pill_mode(pill, 1) %> <%= render_time_representation(%{type: :text, value: value}) %>|
  end

  defp render_departure_time_group(%{type: :text, value: value}, false) do
    render_time_representation(%{type: :text, value: value})
  end

  @spec render_time_representation(Screens.Audio.time_representation()) :: Phoenix.HTML.safe()
  def render_time_representation(%{type: :text, value: :brd}), do: ~E"is now boarding"
  def render_time_representation(%{type: :text, value: :arr}), do: ~E"is now arriving"

  def render_time_representation(%{type: :minutes, value: minutes}) do
    ~E|<%= minutes %> <%= pluralize_minutes(minutes) %>|
  end

  def render_time_representation(%{type: :timestamp, value: timestamp}) do
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

  @spec say_as_address(Phoenix.HTML.unsafe()) :: Phoenix.HTML.safe()
  defp say_as_address(text) do
    ~E|<say-as interpret-as="address"><%= text %></say-as>|
  end

  defp pluralize_minutes(1), do: "minute"
  defp pluralize_minutes(_), do: "minutes"
end
