defmodule ScreensWeb.V2.Audio.ReconstructedAlertSingleScreenViewTest do
  use ExUnit.Case, async: true

  alias ScreensWeb.V2.Audio.ReconstructedAlertSingleScreenView

  defp render_alert(assigns) do
    assigns
    |> ReconstructedAlertSingleScreenView.render_alert()
    |> Phoenix.HTML.safe_to_string()
  end

  test "uses the full remedy in the single-screen fallback" do
    assigns = %{
      issue: "No service",
      remedy: [
        "Use shuttle buses to make connections to North Station",
        "Use shuttle buses to make connections to North Sta"
      ]
    }

    assert render_alert(assigns) ==
             "No service. Use shuttle buses to make connections to North Station"
  end
end
