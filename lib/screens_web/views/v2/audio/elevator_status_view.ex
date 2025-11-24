defmodule ScreensWeb.V2.Audio.ElevatorStatusView do
  use ScreensWeb, :view

  alias ScreensConfig.FreeTextLine

  def render("_widget.ssml", %{
        header: header,
        callout_items: callout_items,
        footer_lines: footer_lines,
        footer_audio: footer_audio
      }) do
    ~E|
      <p>Elevator Status</p>
      <p><%= header %> <%= Enum.join(callout_items, ", ") %></p>
      <p><%= footer(footer_audio, footer_lines) %></p>
    |
  end

  defp footer(nil, lines), do: Enum.map_join(lines, " ", &FreeTextLine.to_plaintext/1)
  defp footer(audio, _lines), do: Enum.join(audio, " ")
end
