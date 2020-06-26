defmodule ScreensWeb.AudioView do
  use ScreensWeb, :view

  import Phoenix.HTML

  @type time_representation ::
          %{type: :text, value: String.t()}
          | %{type: :minutes, value: integer}
          | %{type: :timestamp, value: String.t()}

  @spec render_pill_header(atom()) :: Phoenix.HTML.safe()
  def render_pill_header(:blue), do: ~E"Blue Line"
  def render_pill_header(:bus), do: ~E"Bus"
  def render_pill_header(:cr), do: ~E"Commuter Rail"
  def render_pill_header(:mattapan), do: ~E"Mattapan Line"
  def render_pill_header(:orange), do: ~E"Orange Line"
  def render_pill_header(:red), do: ~E"Red Line"
  def render_pill_header(:silver), do: ~E"Silver Line"

  def render_pill_mode(pill, 1) when pill in ~w[blue orange red cr]a, do: ~E"train"
  def render_pill_mode(pill, _) when pill in ~w[blue orange red cr]a, do: ~E"trains"
  def render_pill_mode(pill, 1) when pill in ~w[bus silver]a, do: ~E"bus"
  def render_pill_mode(pill, _) when pill in ~w[bus silver]a, do: ~E"buses"
  def render_pill_mode(:mattapan, 1), do: ~E"trolley"
  def render_pill_mode(:mattapan, _), do: ~E"trolleys"

  def render_route_destination(route, route_id, destination) do
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
    ~E|Silver Line route <% say_as_address(route_number) %>|
  end

  def render_route(route) do
    if String.contains?(route, "/") do
      for route_part <- String.split(route, "/") do
        say_as_address(route_part)
      end
    else
      say_as_address(route)
    end
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

  def render_departure_group({route_descriptor, departures}) do
    departure_time_groups =
      departures
      |> Enum.map(&%{pill: &1.pill, time_representation: get_time_representation(&1)})
      |> group_departure_time_representations()

    [first | rest] = departure_time_groups

    first_rendered = render_first_departure_time_group(route_descriptor, first)

    rest_rendered = Enum.map(rest, &render_departure_time_group(&1, true))

    ~E|<%= first_rendered %><%= rest_rendered %>|
  end

  defp render_first_departure_time_group({route, route_id, destination}, departure_time) do
    route_destination = render_route_destination(route, route_id, destination)

    departure_time_group = render_departure_time_group(departure_time, false)

    ~E|<s><%= route_destination %> <%= departure_time_group %></s>
|
  end

  defp group_departure_time_representations(departure_time_representations) do
    departure_time_representations
    |> Enum.reduce([], &departure_time_representation_reducer/2)
    |> Enum.map(fn
      %{} = item -> item
      item -> Enum.reverse(item)
    end)
    |> Enum.reverse()
  end

  defp departure_time_representation_reducer(
         %{time_representation: %{type: :text}} = d_time_rep,
         acc
       ) do
    [d_time_rep | acc]
  end

  defp departure_time_representation_reducer(d_time_rep, []) do
    [[d_time_rep]]
  end

  defp departure_time_representation_reducer(d_time_rep, acc) do
    if is_list(hd(acc)) and
         d_time_rep.time_representation.type == hd(hd(acc)).time_representation.type do
      [[d_time_rep | hd(acc)] | tl(acc)]
    else
      [[d_time_rep] | acc]
    end
  end

  defp render_departure_time_group(departure_time_group, with_prefix)
       when is_list(departure_time_group) do
    number = length(departure_time_group)
    %{pill: pill, time_representation: %{type: type}} = hd(departure_time_group)

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
      departure_time_group
      |> Enum.map(&render_time_representation(&1.time_representation))
      |> Enum.intersperse(", ")

    if with_prefix do
      ~E|<s><%= prefix %> <%= preposition %> <%= times %></s>
|
    else
      ~E|<%= preposition %> <%= times %>|
    end
  end

  defp render_departure_time_group(%{pill: pill, time_representation: time_representation}, true) do
    ~E|Next <%= render_pill_mode(pill, 1) %> <% render_time_representation(time_representation) %>|
  end

  defp render_departure_time_group(%{time_representation: time_representation}, false) do
    render_time_representation(time_representation)
  end

  @spec render_time_representation(time_representation) :: Phoenix.HTML.safe()
  def render_time_representation(%{type: :text, value: :brd}), do: ~E"is now boarding"
  def render_time_representation(%{type: :text, value: :arr}), do: ~E"is now arriving"

  def render_time_representation(%{type: :minutes, value: minutes}) do
    ~E|<%= minutes %> <%= pluralize_minutes(minutes) %>|
  end

  def render_time_representation(%{type: :timestamp, value: timestamp}) do
    ~E|<%= timestamp %>|
  end

  @spec say_as_address(Phoenix.HTML.unsafe()) :: Phoenix.HTML.safe()
  defp say_as_address(text) do
    ~E|<say-as interpret-as="address"><%= text %></say-as>|
  end

  defp pluralize_minutes(1), do: "minute"
  defp pluralize_minutes(_), do: "minutes"

  defp get_time_representation(%{
         time: time,
         current_time: current_time,
         vehicle_status: vehicle_status,
         stop_type: stop_type
       }) do
    {:ok, time, _} = DateTime.from_iso8601(time)
    {:ok, current_time, _} = DateTime.from_iso8601(current_time)

    second_difference = DateTime.diff(time, current_time)
    minute_difference = round(second_difference / 60)

    cond do
      vehicle_status === :stopped_at and second_difference <= 90 ->
        %{type: :text, value: :brd}

      second_difference <= 30 ->
        if stop_type === :first_stop,
          do: %{type: :text, value: :brd},
          else: %{type: :text, value: :arr}

      minute_difference < 60 ->
        %{type: :minutes, value: minute_difference}

      true ->
        timestamp =
          time
          |> Timex.to_datetime("America/New_York")
          |> Timex.format!("{h12}:{m} {AM}")

        %{type: :timestamp, value: timestamp}
    end
  end
end
