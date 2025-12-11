defmodule ScreensWeb.V2.Audio.NormalHeaderView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{audio_text: audio_text, branch: branch}) do
    ~E|<p><s>This is the Green Line <%= branch %> branch to <%= audio_text %></s></p>|
  end

  def render("_widget.ssml", %{audio_text: audio_text}) do
    ~E|<p><s>This is <%= audio_text %></s></p>|
  end
end
