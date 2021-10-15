defmodule ScreensWeb.V2.Audio.MockWidgetView do
  use ScreensWeb, :view

  import Phoenix.HTML

  def render("_widget.ssml", %{content: content}) do
    ~E"<s>Mock widget with content: <%= content %></s>"
  end
end
