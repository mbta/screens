defmodule Screens.ElevatorTest do
  use ExUnit.Case, async: true

  alias Screens.Elevator

  import ExUnit.CaptureLog

  describe "get/1" do
    test "gets elevators in each redundancy category" do
      assert Elevator.get("996") == %Elevator{id: "996", redundancy: :nearby}
      assert Elevator.get("918") == %Elevator{id: "918", redundancy: :in_station}

      assert Elevator.get("780") ==
               %Elevator{id: "780", redundancy: {:other, "Request assistance from conductor."}}
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
