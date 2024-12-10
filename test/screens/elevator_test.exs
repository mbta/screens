defmodule Screens.ElevatorTest do
  use ExUnit.Case, async: true

  alias Screens.Elevator

  describe "get/1" do
    test "gets elevators in each redundancy category" do
      assert Elevator.get("996") == %Elevator{id: "996", redundancy: :nearby}
      assert Elevator.get("918") == %Elevator{id: "918", redundancy: :in_station}
      # TODO: summary text for categories 3 and 4 does not exist yet
      assert Elevator.get("958") == %Elevator{id: "958", redundancy: {:different_station, ""}}
      assert Elevator.get("896") == %Elevator{id: "896", redundancy: {:contact, ""}}
    end

    test "returns nil for an elevator with no defined redundancy category" do
      assert Elevator.get("780") == nil
    end

    test "returns nil when the given elevator ID does not exist in the data" do
      assert Elevator.get("foo") == nil
    end
  end
end
