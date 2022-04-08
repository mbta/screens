defmodule ScreensWeb.V2.Audio.AlertsIntroView do
  use ScreensWeb, :view

  def render("_widget.ssml", _data) do
    ~E|<p><s>Current service alerts are also available at <say-as interpret-as="spell-out">MBTA</say-as> dot com slash <break /> alerts</s></p>|
  end
end
