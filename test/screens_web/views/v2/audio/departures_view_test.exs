defmodule ScreensWeb.V2.Audio.DeparturesViewTest do
  use ScreensWeb.ConnCase, async: true

  alias ScreensWeb.V2.Audio.DeparturesView

  describe "no sections" do
    setup :empty

    test "renders an empty state", %{assigns: assigns} do
      assert render(assigns) =~ "There are no upcoming trips at this time"
    end
  end

  describe "only empty sections" do
    setup :empty_sections

    test "renders an empty state", %{assigns: assigns} do
      assert render(assigns) =~ "There are no upcoming trips at this time"
    end
  end

  describe "section with a header" do
    setup :with_header

    test "renders the header content", %{assigns: assigns} do
      assert render(assigns) =~ "Header"
    end
  end

  ## helpers

  defp render(data) do
    "_widget.ssml"
    |> DeparturesView.render(data)
    |> Phoenix.HTML.safe_to_string()
  end

  ## setup

  defp empty(_) do
    [assigns: %{sections: []}]
  end

  defp empty_sections(_) do
    [
      assigns: %{
        sections: [
          %{type: :normal_section, departure_groups: []},
          %{type: :normal_section, departure_groups: []},
          %{type: :normal_section, departure_groups: []}
        ]
      }
    ]
  end

  defp with_header(_) do
    [
      assigns: %{
        sections: [
          %{
            type: :normal_section,
            header: "Header",
            departure_groups: [
              {:notice, "Notice"}
            ]
          }
        ]
      }
    ]
  end
end
