defmodule ScreensWeb.V2.Audio.ElevatorStatusViewTest do
  use ExUnit.Case, async: true

  alias ScreensWeb.V2.Audio.ElevatorStatusView
  alias ScreensConfig.FreeTextLine

  defp render(assigns) do
    "_widget.ssml"
    |> ElevatorStatusView.render(assigns)
    |> Phoenix.HTML.safe_to_string()
    |> String.replace(~r/\n\s+/, "")
  end

  test "uses footer audio instead of footer lines if defined" do
    assigns = %{
      header: "elevators are down:",
      callout_items: ["one", "another"],
      footer_lines: [%FreeTextLine{icon: nil, text: ["go to mbta.com/stops/place-abc for more"]}],
      footer_audio: ["for full list", "call the hotline"]
    }

    expected = [
      "<p>Elevator Status</p>",
      "<p>elevators are down: one, another</p>",
      "<p>for full list call the hotline</p>"
    ]

    assert render(assigns) == Enum.join(expected)
  end

  test "uses footer lines as-is when no footer audio defined" do
    assigns = %{
      header: "elevators are okay",
      callout_items: [],
      footer_lines: [%FreeTextLine{icon: nil, text: ["or have backups"]}],
      footer_audio: nil
    }

    expected = [
      "<p>Elevator Status</p>",
      "<p>elevators are okay </p>",
      "<p>or have backups</p>"
    ]

    assert render(assigns) == Enum.join(expected)
  end
end
