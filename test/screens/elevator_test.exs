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

    test "gets elevators in each entering redundancy category" do
      assert %Elevator{entering_redundancy: :nearby} = Elevator.get("996")
      assert %Elevator{entering_redundancy: :in_station} = Elevator.get("918")
      assert %Elevator{entering_redundancy: :shuttle} = Elevator.get("816")
      assert %Elevator{entering_redundancy: :other} = Elevator.get("970")
    end

    test "gets elevators in each exiting redundancy category" do
      assert %Elevator{exiting_redundancy: :nearby} = Elevator.get("996")
      assert %Elevator{exiting_redundancy: :in_station} = Elevator.get("918")

      assert %Elevator{exiting_redundancy: {:other, "Request assistance from conductor."}} =
               Elevator.get("780")
    end

    test "handles sub-categories of in-station redundancy" do
      assert %Elevator{entering_redundancy: :in_station, exiting_redundancy: :in_station} =
               Elevator.get("842")

      assert %Elevator{entering_redundancy: :in_station, exiting_redundancy: :in_station} =
               Elevator.get("771")
    end

    test "only interprets sub-category 3B as shuttle for entering redundancy" do
      assert %Elevator{entering_redundancy: :shuttle} = Elevator.get("945")
      assert %Elevator{entering_redundancy: :other} = Elevator.get("958")
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
