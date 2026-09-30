defmodule ScreensWeb.V2.Audio.ReconstructedAlertViewTest do
  use ExUnit.Case, async: true

  alias ScreensWeb.V2.Audio.ReconstructedAlertView

  defp render(assigns) do
    "_widget.ssml"
    |> ReconstructedAlertView.render(assigns)
    |> Phoenix.HTML.safe_to_string()
  end

  test "uses the full issue for a downstream station closure" do
    assigns = %{
      issue: [
        "This is a test alert affecting both North Station and Tufts Medical Center for some reason",
        "This is a test alert affecting both North Sta and Tufts Med for some reason"
      ],
      remedy: "",
      cause: "due to maintenance",
      region: :outside,
      effect: :station_closure
    }

    assert render(assigns) ==
             "<p>This is a test alert affecting both North Station and Tufts Medical Center for some reason due to maintenance.</p>"
  end

  test "uses the full issue for a delay" do
    assigns = %{
      issue: [
        "Delays of about 20 minutes affecting North Station",
        "Delays of about 20 minutes affecting North Sta"
      ],
      routes: [%{color: "Orange"}],
      urgent: false,
      effect: :delay
    }

    assert render(assigns) ==
             "<p>Orange Line delay. Delays of about 20 minutes affecting North Station.</p>"
  end

  test "renders a delay affecting a single green line branch" do
    assigns = %{
      issue: [
        "Delays of about 20 minutes affecting Park Street",
        "Delays of about 20 minutes affecting Park St"
      ],
      routes: [%{color: "Green-B"}],
      urgent: false,
      effect: :delay
    }

    assert render(assigns) ==
             "<p>Green-B Line delay. Delays of about 20 minutes affecting Park Street.</p>"
  end

  test "renders a delay affecting two green line branches" do
    assigns = %{
      issue: [
        "Delays of about 20 minutes affecting Park Street",
        "Delays of about 20 minutes affecting Park St"
      ],
      routes: [%{color: "Green-B"}, %{color: "Green-C"}],
      urgent: false,
      effect: :delay
    }

    assert render(assigns) ==
             "<p>Green-B and Green-C Lines delay. Delays of about 20 minutes affecting Park Street.</p>"
  end

  test "renders a delay affecting three green line branches" do
    assigns = %{
      issue: [
        "Delays of about 20 minutes affecting Park Street",
        "Delays of about 20 minutes affecting Park St"
      ],
      routes: [%{color: "Green-B"}, %{color: "Green-C"}, %{color: "Green-D"}],
      urgent: false,
      effect: :delay
    }

    assert render(assigns) ==
             "<p>Green-B, Green-C, and Green-D Lines delay. Delays of about 20 minutes affecting Park Street.</p>"
  end

  test "renders a delay affecting two non-green line branches" do
    assigns = %{
      issue: [
        "Delays of about 20 minutes affecting State Street",
        "Delays of about 20 minutes affecting State St"
      ],
      routes: [%{color: "Blue"}, %{color: "Orange"}],
      urgent: false,
      effect: :delay
    }

    assert render(assigns) ==
             "<p>Blue and Orange Lines delay. Delays of about 20 minutes affecting State Street.</p>"
  end

  test "renders a delay affecting three non-green line branches" do
    assigns = %{
      issue: [
        "Delays of about 20 minutes affecting State Street",
        "Delays of about 20 minutes affecting State St"
      ],
      routes: [%{color: "Blue"}, %{color: "Orange"}, %{color: "Red"}],
      urgent: false,
      effect: :delay
    }

    assert render(assigns) ==
             "<p>Blue, Orange, and Red Lines delay. Delays of about 20 minutes affecting State Street.</p>"
  end

  test "uses the full issue for other alerts" do
    assigns = %{
      issue: ["No trains at Government Center", "No trains at Gov't Ctr"],
      remedy: "Seek alternate route",
      cause: "due to maintenance",
      location: "",
      routes: [%{color: "Red"}],
      effect: :suspension
    }

    assert render(assigns) ==
             "<p>Red Line alert. No trains at Government Center due to maintenance. Please seek an alternate route.</p>"
  end
end
