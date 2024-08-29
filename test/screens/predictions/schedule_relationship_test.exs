defmodule Screens.Predictions.ScheduleRelationshipTest do
  alias Screens.Predictions.ScheduleRelationship
  use ExUnit.Case, async: true

  describe "parse/1" do
    test "parses nil to :scheduled" do
      assert :scheduled == ScheduleRelationship.parse(nil)
    end

    test "parses \"ADDED\" to :added" do
      assert :added == ScheduleRelationship.parse("ADDED")
    end

    test "parses \"CANCELLED\" to :cancelled" do
      assert :cancelled == ScheduleRelationship.parse("CANCELLED")
    end

    test "parses \"NO_DATA\" to :no_data" do
      assert :no_data == ScheduleRelationship.parse("NO_DATA")
    end

    test "parses \"SKIPPED\" to :skipped" do
      assert :skipped == ScheduleRelationship.parse("SKIPPED")
    end

    test "parses \"UNSCHEDULED\" to :unscheduled" do
      assert :unscheduled == ScheduleRelationship.parse("UNSCHEDULED")
    end
  end
end
