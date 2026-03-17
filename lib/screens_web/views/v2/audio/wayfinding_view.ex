defmodule ScreensWeb.V2.Audio.WayfindingView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{text: text}) do
    ~E|<p><s><%= text %></s></p>|
  end
end
