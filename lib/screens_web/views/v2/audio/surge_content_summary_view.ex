defmodule ScreensWeb.V2.Audio.SurgeContentSummaryView do
  use ScreensWeb, :view

  def render("_widget.ssml", _) do
    ~E|<p>No Orange Line trains are in service.</p>
    <p>Alternative travel options include the Commuter Rail, <s>blue bikes</s>, and shuttle buses.
    Riders can take the Commuter Rail for free, and free Bluebike passes are available.</p>|
  end
end
