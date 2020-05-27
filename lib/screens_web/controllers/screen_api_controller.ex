defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller
  require Logger

  def show(conn, %{"id" => screen_id, "version" => _version, "date" => date, "time" => time}) do
    data = Screens.ScreenData.by_screen_id_with_datetime(screen_id, date, time)

    json(conn, data)
  end

  def show(conn, %{"id" => screen_id, "version" => version}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ = Screens.LogScreenData.log_data_request(screen_id, version, is_screen)

    data =
      Screens.ScreenData.by_screen_id_with_override_and_version(screen_id, version, is_screen)

    json(conn, data)
  end

  def audio(conn, %{"id" => screen_id, "version" => version}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    # _ = Screens.LogScreenData.log_data_request(screen_id, version, is_screen)

    %{station_name: station_name, sections: sections, current_time: current_time} =
      Screens.ScreenData.by_screen_id_with_override_and_version(screen_id, version, is_screen)

    text = "Upcoming trips at #{station_name}: #{speak_sections(sections, current_time)}."

    {:ok, %{body: audio_data}} =
      text
      |> ExAws.Polly.synthesize_speech(lexicon_names: ["mbtalexicon"])
      |> ExAws.request()

    send_download(conn, {:binary, audio_data},
      filename: "poly_sample.mp3",
      content_type: "audio/mpeg",
      disposition: :inline
    )
  end

  defp speak_sections(sections, current_time) do
    sections
    |> Enum.map(&speak_section(&1, current_time))
    |> Enum.join(", ")
  end

  defp speak_section(section, current_time) do
    section.departures
    |> Enum.take(2)
    |> Enum.map(&speak_departure(&1, section.name, current_time))
    |> Enum.join(", ")
  end

  defp speak_departure(d, section_name, current_time) do
    t1 = NaiveDateTime.from_iso8601!(current_time)
    t2 = NaiveDateTime.from_iso8601!(d.time)
    time = div(NaiveDateTime.diff(t2, t1, :second), 60)
    minutes = if time == 1, do: "minute", else: "minutes"

    case Integer.parse(d.route) do
      {bus_route, ""} -> "bus route #{bus_route} to #{d.destination} in #{time} #{minutes}"
      :error -> "#{section_name} to #{d.destination} in #{time} #{minutes}"
    end
  end
end
