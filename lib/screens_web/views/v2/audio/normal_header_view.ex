defmodule ScreensWeb.V2.Audio.NormalHeaderView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{read_as: read_as, branch: branch}) do
    ~E|<p><s>This is the Green Line <%= branch %> branch to <%= read_as %></s></p>|
  end

  def render("_widget.ssml", %{read_as: read_as}) do
    ~E|<p><s>This is <%= read_as %></s></p>|
  end
end
