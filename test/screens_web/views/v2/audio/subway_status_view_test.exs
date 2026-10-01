defmodule ScreensWeb.V2.Audio.SubwayStatusViewTest do
  use ExUnit.Case

  alias ScreensWeb.V2.Audio.SubwayStatusView

  defp render_subway_status(assigns) do
    "_widget.ssml"
    |> SubwayStatusView.render(assigns)
    |> Phoenix.HTML.safe_to_string()
  end

  describe "render/2" do
    @bl_pill %{type: :text, text: "BL", color: :blue}
    @gl_pill %{type: :text, text: "GL", color: :green}
    @ol_pill %{type: :text, text: "OL", color: :orange}
    @rl_pill %{type: :text, text: "RL", color: :red}

    @normal_service %{
      blue: %{type: :contracted, alerts: [%{route_pill: @bl_pill, status: "Normal Service"}]},
      green: %{type: :contracted, alerts: [%{route_pill: @gl_pill, status: "Normal Service"}]},
      orange: %{type: :contracted, alerts: [%{route_pill: @ol_pill, status: "Normal Service"}]},
      red: %{type: :contracted, alerts: [%{route_pill: @rl_pill, status: "Normal Service"}]}
    }

    defp gl_pill(branches), do: Map.put(@gl_pill, :branches, branches)

    defp say_as_spell_out(text), do: "<say-as interpret-as=\"spell-out\">#{text}</say-as>"

    test "renders a green line branch with a single tracking alert" do
      assigns = %{
        @normal_service
        | green: %{
            type: :contracted,
            alerts: [
              %{
                location: %{full: "Due to Single Tracking"},
                status: "Delays up to 15 minutes",
                route_pill: gl_pill([:c]),
                effect: :delay,
                severity: 5
              }
            ]
          }
      }

      assert render_subway_status(assigns) =~
               "Green Line branch, #{say_as_spell_out("C")}, has Delays up to 15 minutes Due to Single Tracking"
    end

    test "renders a route with the location text 'Entire line' for whole-line alerts" do
      assigns = %{
        @normal_service
        | green: %{
            type: :extended,
            alert: %{
              effect: :shuttle,
              status: "Shuttle Bus",
              location: "Entire line"
            }
          }
      }

      assert render_subway_status(assigns) =~
               "The Green Line has a Shuttle Bus on the Entire line"
    end

    test "renders directional alerts" do
      assigns = %{
        @normal_service
        | green: %{
            type: :extended,
            alert: %{
              effect: :shuttle,
              status: "Shuttle Bus",
              location: "Southbound"
            }
          }
      }

      assert render_subway_status(assigns) =~ "The Green Line has a Southbound Shuttle Bus"
    end

    test "renders partial line suspensions that apply to multiple GL branches" do
      assigns = %{
        @normal_service
        | green: %{
            type: :extended,
            alert: %{
              route_pill: gl_pill([:b, :c, :d]),
              status: "Suspension",
              location: %{full: "North Station ↔ Park Street"}
            }
          }
      }

      assert render_subway_status(assigns) =~
               "Green Line branches, #{say_as_spell_out("B")}, \
#{say_as_spell_out("C")}, and, #{say_as_spell_out("D")}, have a Suspension \
between North Station and Park Street"
    end

    test "renders with an alert for a single location" do
      assigns = %{
        @normal_service
        | green: %{
            type: :extended,
            alert: %{
              effect: :shuttle,
              status: "Shuttle Bus",
              location: "Science Park"
            }
          }
      }

      assert render_subway_status(assigns) =~ "The Green Line has a Shuttle Bus at Science Park"
    end
  end
end
