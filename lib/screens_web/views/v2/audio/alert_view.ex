defmodule ScreensWeb.V2.Audio.AlertView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{description: description}) do
    ~E|<p>Alert:</p> <p><%= description %></p>|
  end
end
