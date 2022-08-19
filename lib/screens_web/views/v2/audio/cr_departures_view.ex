defmodule ScreensWeb.V2.Audio.CRDeparturesView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{departures: []}) do
    ~E|<p>There are no upcoming trips at this time</p>|
  end

  def render("_widget.ssml", %{departures: departures, destination: destination, time_to_destination: time_to_destination, show_via_headsigns_message: show_via_headsigns_message}) do  
    ~E|
    <p>Upcoming Commuter Rail trips:</p>
    <%= render_departures(departures) %>
    <%= render_via_headsign_message(show_via_headsigns_message) %>
    <%= render_eta(time_to_destination, destination) %>
    <p>Riders can take the Commuter Rail free of charge.</p>
    |
  end

  defp render_via_headsign_message(true) do
    ~E|<p>Trains via Ruggles stop at Ruggles, but not at Forest Hills.
    Trains via Forest Hills stop at Ruggles and Forest Hills.</p>|
  end
  
  defp render_via_headsign_message(_), do: ""

  # Number starts with vowel / consonant
  defp render_eta(eta, destination) do
    first_number = eta
    |> String.split("-")
    |> List.first()
    article = if (first_number in ["8", "11", "18"]) do
      "an"
    else
      "a"
    end
    ~E|<p>It's <%= article %> <%= eta %> minute train ride to <%= destination %>.</p>|
  end

  defp render_departure(departure, previous_departure) do
    %{
      headsign: headsign,
      time: time,
      track_number: track_number
    } = departure

    prefix =
      if not is_nil(previous_departure) and (headsign === previous_departure.headsign) do
        "The following train to"
      else
        "The next train to"
      end

    track = if (track_number) do
      "on track " <> Integer.to_string(track_number) <> "."
    else
      ". We will announce the track for this train soon."
    end

    content =
      build_text([
        prefix,
        render_headsign(headsign),
        if(time_is_arr_brd?(time), do: nil, else: "arrives"),
        preposition_for_time_type(time.type),
        {time, &render_time/1},
        track
      ])

    ~E|<s><%= content %></s>|
  end

  defp render_departures(departures) do
    departures_with_index = Enum.with_index(departures)
    
    # Is this the best way to iterate and track previous item in array?
    departures_with_index
    |> Enum.map(fn {departure, i} ->
      if (i === 0) do
        render_departure(departure, nil)
      else
        render_departure(departure, Enum.at(departures, i-1))
      end
    end)
  end

  defp render_time(%{type: :text, text: "BRD"}), do: "is now boarding"
  defp render_time(%{type: :text, text: "ARR"}), do: "is now arriving"
  defp render_time(%{type: :text, text: "Now"}), do: "is now arriving"

  defp render_time(%{type: :minutes, minutes: minute_diff}) do
    ~E|<%= minute_diff %> <%= pluralize_minutes(minute_diff) %>|
  end

  defp render_time(%{type: :timestamp, timestamp: timestamp, ampm: ampm}) do
    ~E|<%= timestamp %><%= ampm %>|
  end

  defp preposition_for_time_type(:text), do: nil
  defp preposition_for_time_type(:minutes), do: "in"
  defp preposition_for_time_type(:timestamp), do: "at"

  defp render_headsign(%{headsign: headsign, variation: nil}) do
    ~E|<%= headsign %>|
  end

  defp render_headsign(%{headsign: headsign, variation: variation}) do
    ~E|<%= headsign %> <%= variation %>|
  end

  defp pluralize_minutes(1), do: "minute"
  defp pluralize_minutes(_), do: "minutes"

  defp time_is_arr_brd?(time) do
    match?(%{type: :text}, time)
  end

  defp identity_render(value), do: ~E|<%= value %>|

  defp build_text(value_renderers) do
    value_renderers
    |> Enum.reject(fn
      {value, renderer} when is_function(renderer) -> is_nil(value)
      value -> is_nil(value)
    end)
    |> Enum.map(fn
      {value, renderer} when is_function(renderer) -> renderer.(value)
      value -> identity_render(value)
    end)
    |> Enum.intersperse(~E| |)
  end
end
