defmodule ScreensWeb.V2.Audio.ContentSummaryView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{lines_at_station: lines}) do
    ~E|<p><s>You will hear the subway service overview, the current alerts for the <%= render_lines_at_station(lines) %>, and system elevator closures</s></p>|
  end

  defp render_lines_at_station([line]) do
    ~E|<%= line %> line|
  end

  defp render_lines_at_station([line1, line2]) do
    ~E|<%= line1 %> and <%= line2 %> lines|
  end

  defp render_lines_at_station(lines) do
    {all_but_last, last} = Enum.split(lines, -1)

    ~E|<%= Enum.join(all_but_last, ", ") %>, and <%= last %> lines|
  end
end
