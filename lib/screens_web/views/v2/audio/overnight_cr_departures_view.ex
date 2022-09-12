defmodule ScreensWeb.V2.Audio.OvernightCRDeparturesView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        direction: direction,
        last_schedule_departure_time: last_schedule_departure_time,
        last_schedule_headsign_stop: last_schedule_headsign_stop,
        last_schedule_headsign_via: last_schedule_headsign_via
      }) do
    ~E|
    <p><%= direction %> Commuter Rail trains: </p>
    <p>There are no more <%= direction %> Commuter Rail trains running this evening.</p>
    <p>
      The last <%= direction %> train tomorrow night leaves at <%= Timex.format!(last_schedule_departure_time, "{h12}:{m} {AM}") %>
      for <%= last_schedule_headsign_stop %>, and stops at <%= last_schedule_headsign_via %>.
    </p>
    <p>For full Commuter Rail schedules, visit mbta.com/schedules/commuter-rail.</p>
    |
  end
end
