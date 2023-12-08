defmodule ScreensWeb.V2.Audio.AlertView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{description: description}) do
    ~E|<p><s>Alert: <%= description %></s></p>|
  end
end
