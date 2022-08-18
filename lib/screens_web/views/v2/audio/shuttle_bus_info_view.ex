defmodule ScreensWeb.V2.Audio.ShuttleBusInfoView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        minutes_range_to_destination: minutes_range_to_destination,
        destination: destination,
        audio_boarding_instructions: boarding_instructions
      }) do
    ~E|
    <p>Shuttle buses.</p>
    <p><%= boarding_instructions %></p>
    <p><%= render_time_estimate(minutes_range_to_destination, destination) %></p>
    <p>All shuttle buses are accessible and free.</p>
    <p>Accessible vans are also available upon request.</p>
    |
  end

  defp render_time_estimate(minute_range, destination) do
    "It's a #{minute_range} minute bus ride to #{destination}."
  end
end
