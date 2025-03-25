defmodule Screens.V2.WidgetInstance.ElevatorClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Elevator.Closure
  alias Screens.V2.WidgetInstance.ElevatorClosures
  alias Screens.V2.WidgetInstance.ElevatorClosures.{Station, Upcoming}
  alias ScreensConfig.Screen.Elevator

  @instance %ElevatorClosures{
    app_params: %Elevator{
      elevator_id: "1",
      alternate_direction_text: "Test",
      accessible_path_direction_arrow: :n
    },
    now: ~U[2025-01-01 00:00:00Z],
    station_id: "place-abc",
    stations_with_closures: [
      %Station{
        name: "Forest Hills",
        route_icons: ["Orange"],
        closures: [%Closure{id: "222", name: "FH Elevator"}]
      }
    ]
  }

  describe "serialize/1" do
    test "returns map with ids and closures" do
      assert WidgetInstance.serialize(@instance) == %{
               id: @instance.app_params.elevator_id,
               station_id: @instance.station_id,
               stations_with_closures: @instance.stations_with_closures,
               upcoming_closure: nil
             }
    end

    test "serializes an upcoming closure" do
      instance = %{
        @instance
        | upcoming_closure: %Upcoming{period: {~U[2025-01-10 08:00:00Z], nil}, summary: "what2do"}
      }

      assert %{
               upcoming_closure: %{
                 banner: %{title: "Friday, Jan\u00A010", postfix: "until further notice"},
                 details: %{
                   summary: "what2do",
                   titles: ["Friday, January\u00A010", "Friday, Jan.\u00A010"],
                   postfix: "until further notice"
                 }
               }
             } = WidgetInstance.serialize(instance)
    end
  end

  describe "upcoming closure serialization" do
    defp serialize(today, start_date, end_date \\ nil) do
      %{upcoming_closure: closure} =
        WidgetInstance.serialize(%{
          @instance
          | now: DateTime.new!(today, ~T[12:00:00], "America/New_York"),
            upcoming_closure: %Upcoming{period: {start_date, end_date}}
        })

      closure
    end

    @nbsp "\u00A0"

    test "both titles are 'Tomorrow' when the closure starts tomorrow" do
      assert %{banner: %{title: "Tomorrow"}, details: %{titles: ["Tomorrow"]}} =
               serialize(~D[2025-01-01], ~D[2025-01-02])
    end

    test "both titles are relative when the closure starts later this Monday-based week" do
      assert %{banner: %{title: "This Sunday"}, details: %{titles: ["This Sunday"]}} =
               serialize(~D[2025-01-01], ~D[2025-01-05])
    end

    test "titles use month+day when no special case applies" do
      assert %{
               banner: %{title: "Monday, Jan#{@nbsp}6"},
               details: %{titles: ["Monday, January#{@nbsp}6", "Monday, Jan.#{@nbsp}6"]}
             } =
               serialize(~D[2025-01-01], ~D[2025-01-06])
    end

    test "postfix uses 'until further notice' when the closure is indefinite" do
      assert %{
               banner: %{postfix: "until further notice"},
               details: %{postfix: "until further notice"}
             } =
               serialize(~D[2025-01-01], ~D[2025-01-02])
    end

    test "postfix clarifies the start and end month+day when the title is relative" do
      assert %{
               banner: %{postfix: "Jan#{@nbsp}2 – 3"},
               details: %{postfix: "January#{@nbsp}2 – 3"}
             } =
               serialize(~D[2025-01-01], ~D[2025-01-02], ~D[2025-01-03])
    end

    test "postfix clarifies the date for a single-day closure when the title is relative" do
      assert %{banner: %{postfix: "Jan#{@nbsp}2"}, details: %{postfix: "January#{@nbsp}2"}} =
               serialize(~D[2025-01-01], ~D[2025-01-02], ~D[2025-01-02])
    end

    test "postfix clarifies the date range of closures when the title is relative" do
      assert %{
               banner: %{postfix: "Jan#{@nbsp}2 – 3"},
               details: %{postfix: "January#{@nbsp}2 – 3"}
             } =
               serialize(~D[2025-01-01], ~D[2025-01-02], ~D[2025-01-03])
    end

    test "postfix clarifies the date of month-spanning closures when the title is relative" do
      assert %{
               banner: %{postfix: "Jan#{@nbsp}2 – Feb#{@nbsp}1"},
               details: %{postfix: "January#{@nbsp}2 – February#{@nbsp}1"}
             } =
               serialize(~D[2025-01-01], ~D[2025-01-02], ~D[2025-02-01])
    end

    test "when title is not relative, details postfix uses 'through', banner uses full date" do
      assert %{
               banner: %{postfix: "Jan#{@nbsp}6 – 8"},
               details: %{postfix: "through January#{@nbsp}8"}
             } =
               serialize(~D[2025-01-01], ~D[2025-01-06], ~D[2025-01-08])

      assert %{
               banner: %{postfix: "Jan#{@nbsp}6 – Feb#{@nbsp}1"},
               details: %{postfix: "through February#{@nbsp}1"}
             } =
               serialize(~D[2025-01-01], ~D[2025-01-06], ~D[2025-02-01])
    end

    test "postfix is nil for a single-day closure when the title already provides the date" do
      assert %{banner: %{postfix: nil}, details: %{postfix: nil}} =
               serialize(~D[2025-01-01], ~D[2025-01-06], ~D[2025-01-06])
    end
  end

  describe "fixed values" do
    test "are expected" do
      assert [1] == WidgetInstance.priority(@instance)
      assert [:main_content] == WidgetInstance.slot_names(@instance)
      assert :elevator_closures == WidgetInstance.widget_type(@instance)
      assert %{} == WidgetInstance.audio_serialize(@instance)
      assert [0] == WidgetInstance.audio_sort_key(@instance)
      refute WidgetInstance.audio_valid_candidate?(@instance)
      assert ScreensWeb.V2.Audio.ElevatorClosuresView == WidgetInstance.audio_view(@instance)
    end
  end
end
