defmodule ScreensWeb.V2.Audio.BottomScreenFillerView do
  use ScreensWeb, :view

  def render("_widget.ssml", _) do
    ~E""
  end
end
