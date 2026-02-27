defmodule ScreensWeb.V2.Audio.NullView do
  @moduledoc "View for widgets with no audio equivalence. Renders nothing."

  use ScreensWeb, :view

  def render("_widget.ssml", _), do: ~E""
end
