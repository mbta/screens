defmodule ScreensWeb.V2.Audio.NormalHeaderView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{text: text}) do
    ~E|<p><s>This is <%= text %></s></p>|
  end
end
