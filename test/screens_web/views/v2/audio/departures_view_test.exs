defmodule ScreensWeb.V2.Audio.DeparturesViewTest do
  use ScreensWeb.ConnCase, async: true

  alias ScreensWeb.V2.Audio.DeparturesView

  describe "no sections" do
    test "renders an empty state" do
      assigns = %{sections: []}

      assert render(assigns) =~ "There are no upcoming trips at this time"
    end
  end

  describe "only empty sections" do
    test "renders an empty state" do
      assigns = %{
        sections: [
          %{type: :normal_section, departure_groups: []},
          %{type: :normal_section, departure_groups: []},
          %{type: :normal_section, departure_groups: []}
        ]
      }

      assert render(assigns) =~ "There are no upcoming trips at this time"
    end
  end

  describe "section with a header" do
    test "renders the header content" do
      assigns = %{
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

      assert render(assigns) =~ "Header"
    end
  end

  ## helpers

  defp render(data) do
    "_widget.ssml"
    |> DeparturesView.render(data)
    |> Phoenix.HTML.safe_to_string()
  end
end
