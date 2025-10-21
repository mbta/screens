defmodule ScreensWeb.V2.Audio.ElevatorStatusNewView do
  use ScreensWeb, :view

  alias ScreensConfig.FreeTextLine

  def render("_widget.ssml", %{
        header: header,
        callout_items: callout_items,
        footer_lines: footer_lines
      }) do
    ~E|
      <p>Elevator Status</p>
      <p><%= header %> <%= Enum.join(callout_items, ", ") %></p>
      <p><%= footer(footer_lines) %></p>
    |
  end

  defp footer(lines) do
    lines |> Enum.map_join(" ", &FreeTextLine.to_plaintext/1) |> adjust_urls()
  end

  defp adjust_urls(text) do
    text
    |> String.split(~r/(place-\w+)/, include_captures: true)
    |> Enum.map(fn
      "place-" <> rest -> ~E|place<say-as interpret-as="spell-out">-<%= rest %></say-as>|
      text -> text
    end)
  end
end
