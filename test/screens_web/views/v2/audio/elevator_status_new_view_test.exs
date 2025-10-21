defmodule ScreensWeb.V2.Audio.ElevatorStatusNewViewTest do
  use ExUnit.Case, async: true

  alias ScreensWeb.V2.Audio.ElevatorStatusNewView
  alias ScreensConfig.FreeTextLine

  defp render(assigns) do
    "_widget.ssml"
    |> ElevatorStatusNewView.render(assigns)
    |> Phoenix.HTML.safe_to_string()
    |> String.replace(~r/\n\s+/, "")
  end

  test "spells out parent station IDs in URLs" do
    assigns = %{
      header: "elevators are down:",
      callout_items: ["one", "another"],
      footer_lines: [%FreeTextLine{icon: nil, text: ["go to mbta.com/stops/place-abc for more"]}]
    }

    expected = [
      "<p>Elevator Status</p>",
      "<p>elevators are down: one, another</p>",
      "<p>go to mbta.com/stops/place<say-as interpret-as=\"spell-out\">-abc</say-as> for more</p>"
    ]

    assert render(assigns) == Enum.join(expected)
  end
end
