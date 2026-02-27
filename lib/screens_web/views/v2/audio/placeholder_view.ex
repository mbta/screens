defmodule ScreensWeb.V2.Audio.PlaceholderView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{text: text}) do
    ~E"Placeholder: <%= text %>."
  end
end
