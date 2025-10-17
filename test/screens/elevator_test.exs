defmodule Screens.ElevatorTest do
  use ExUnit.Case, async: true

  alias Screens.Elevator

  import ExUnit.CaptureLog

  describe "get/1" do
    test "works for every entry in the data" do
      all_ids =
        :screens
        |> :code.priv_dir()
        |> Path.join("elevators.json")
        |> File.read!()
        |> Jason.decode!()
        |> Map.keys()

      Enum.each(all_ids, fn id -> assert %Elevator{id: ^id} = Elevator.get(id) end)
    end

    test "returns alternate elevator IDs" do
      assert %Elevator{alternate_ids: []} = Elevator.get("780")
      assert %Elevator{alternate_ids: ~w[901 927 919]} = Elevator.get("918")
    end

    test "gets elevators in each redundancy category" do
      assert %Elevator{redundancy: :nearby} = Elevator.get("996")
      assert %Elevator{redundancy: :in_station} = Elevator.get("918")
      assert %Elevator{redundancy: :backtrack} = Elevator.get("830")
      assert %Elevator{redundancy: :shuttle} = Elevator.get("816")
      assert %Elevator{redundancy: :other} = Elevator.get("970")
    end

    test "gets redundant route exiting summaries" do
      assert %Elevator{exiting_summary: "Request assistance from conductor."} =
               Elevator.get("780")
    end

    test "returns nil and logs a warning when redundancy data does not exist" do
      logs =
        capture_log(fn ->
          assert Elevator.get("nonexistent") == nil
        end)

      assert logs =~ "[warning] elevator_redundancy_not_found"
    end
  end
end
