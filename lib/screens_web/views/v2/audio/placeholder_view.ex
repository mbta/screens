defmodule ScreensWeb.V2.Audio.PlaceholderView do
  use ScreensWeb, :view

  def render("_widget.ssml", _) do
    ~E""
  end
end
