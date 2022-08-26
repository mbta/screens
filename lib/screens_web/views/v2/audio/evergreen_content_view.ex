defmodule ScreensWeb.V2.Audio.EvergreenContentView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{text_for_audio: text_for_audio}) do
    ~E"<p><%= text_for_audio %></p>"
  end
end
