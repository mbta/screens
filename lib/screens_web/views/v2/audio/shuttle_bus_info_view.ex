defmodule ScreensWeb.V2.Audio.ShuttleBusInfoView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        minutes_range_to_destination: minutes_range_to_destination,
        destination: destination
      }) do
    ~E|<p>Estimated <%= minutes_range_to_destination %> minute to <%= destination %></p>|
  end
end
