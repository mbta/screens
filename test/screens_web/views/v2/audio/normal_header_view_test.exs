defmodule ScreensWeb.V2.Audio.NormalHeaderViewTest do
  use ExUnit.Case, async: true

  alias ScreensWeb.V2.Audio.NormalHeaderView

  defp render_normal_header(assigns) do
    "_widget.ssml"
    |> NormalHeaderView.render(assigns)
    |> Phoenix.HTML.safe_to_string()
  end

  describe "render/2" do
    test "renders a green line branch" do
      assigns = %{
        branch: "C",
        text: "Cleveland Circle"
      }

      assert render_normal_header(assigns) =~
               "This is the Green Line C branch to Cleveland Circle"
    end

    test "renders a non-green line route" do
      assigns = %{
        text: "Forest Hills"
      }

      assert render_normal_header(assigns) =~ "This is Forest Hills"
    end
  end
end
