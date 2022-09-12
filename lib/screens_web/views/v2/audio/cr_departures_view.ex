defmodule ScreensWeb.V2.Audio.CRDeparturesView do
  use ScreensWeb, :view
  alias ScreensWeb.V2.Audio.DeparturesView

  def render("_widget.ssml", %{departures: []}) do
    ~E|<p>There are no upcoming trips at this time</p>|
  end

  def render("_widget.ssml", %{
        departures: departures,
        station: station,
        destination: destination,
        time_to_destination: time_to_destination,
        direction: direction
      }) do
    ~E|
    <p>Upcoming <%= direction %> Commuter Rail trains:</p>
    <%= render_departures(departures, station) %>
    <%= render_eta(time_to_destination, destination) %>
    <p>Riders can take the Commuter Rail free of charge.</p>
    |
  end

  # Number starts with vowel / consonant
  defp render_eta(eta, destination) do
    first_number =
      eta
      |> String.split("-")
      |> List.first()

    article =
      if first_number in ["8", "11", "18"] do
        "an"
      else
        "a"
      end

    ~E|<p>It's <%= article %> <%= eta %> minute train ride to <%= destination %>.</p>|
  end

  defp render_departure(departure, previous_departure, station, station) do
    %{
      headsign: headsign,
      time: time,
      track_number: track_number
    } = departure

    prefix =
      if not is_nil(previous_departure) and headsign === previous_departure.headsign do
        "The following train to"
      else
        "The next train to"
      end

    track =
      cond do
        track_number -> "on track " <> Integer.to_string(track_number) <> ". "
        # Omit track number at Forest Hills
        station === "place-forhl" -> ". "
        true -> ". We will announce the track for this train soon. "
      end

    content =
      DeparturesView.build_text([
        prefix,
        render_headsign(headsign),
        if(time_is_arr_brd?(time), do: nil, else: scheduling_phrase(time)),
        {time.departure_time, &render_time/1},
        delayed_clause(time),
        track
      ])

    ~E|<%= content %>|
  end

  defp render_departures(departures, station) do
    departures_with_index = Enum.with_index(departures)

    # Is this the best way to iterate and track previous item in array?
    departures_with_index
    |> Enum.map(fn {departure, i} ->
      if i === 0 do
        render_departure(departure, nil, station, station)
      else
        render_departure(departure, Enum.at(departures, i - 1), station, station)
      end
    end)
  end

  defp render_time(%{type: :text, text: "BRD"}), do: "is now boarding"
  defp render_time(%{type: :text, text: "ARR"}), do: "is now arriving"
  defp render_time(%{type: :text, text: "Now"}), do: "is now arriving"

  defp render_time(%{type: :minutes, minutes: minute_diff}) do
    ~E|<%= minute_diff %> <%= pluralize_minutes(minute_diff) %>|
  end

  defp render_time(time) do
    Timex.format!(time, "{h12}:{m} {AM}")
  end

  defp scheduling_phrase(%{departure_type: :schedule, is_delayed: false}),
    do: "is scheduled to arrive at"

  defp scheduling_phrase(%{departure_type: :schedule, is_delayed: true}),
    do: "was scheduled to arrive at"

  defp scheduling_phrase(%{departure_time: %{type: :text}}), do: nil
  defp scheduling_phrase(%{departure_time: %{type: :minutes}}), do: "departs in"
  defp scheduling_phrase(_), do: "arrives at"

  defp delayed_clause(%{departure_type: :schedule, is_delayed: true}),
    do: "but is currently delayed."

  defp delayed_clause(_), do: ""

  defp render_headsign(%{headsign: headsign, station_service_list: [station1, station2]}) do
    via_string =
      cond do
        station1.service and station2.service -> "via #{station1.name} and #{station2.name}"
        station1.service -> "via #{station1.name}"
        station2.service -> "via #{station2.name}"
        true -> ""
      end

    ~E|<%= headsign %> <%= via_string %>|
  end

  defp pluralize_minutes(1), do: "minute"
  defp pluralize_minutes(_), do: "minutes"

  defp time_is_arr_brd?(time) do
    match?(%{type: :text}, time)
  end
end
