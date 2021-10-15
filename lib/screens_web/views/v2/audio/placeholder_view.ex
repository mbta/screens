defmodule ScreensWeb.V2.Audio.PlaceholderView do
  use ScreensWeb, :view

  import Phoenix.HTML

  def render("_widget.ssml", _) do
    ~E""
  end
end
