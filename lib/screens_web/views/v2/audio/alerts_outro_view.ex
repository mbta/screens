defmodule ScreensWeb.V2.Audio.AlertsOutroView do
  use ScreensWeb, :view

  def render("_widget.ssml", _data) do
    ~E|<p><s>For more information, go to <say-as interpret-as="spell-out">MBTA</say-as> dot com slash <break /> alerts</s></p>|
  end
end
