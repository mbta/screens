defmodule ScreensWeb.V2.Audio.AlertView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{header: header}) do
    ~E|<p>Alert:</p> <p><%= header %></p>|
  end
end
