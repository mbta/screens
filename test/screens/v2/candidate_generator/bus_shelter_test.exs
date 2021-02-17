defmodule Screens.V2.CandidateGenerator.BusShelterTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.BusShelter

  describe "candidate_templates/0" do
    test "returns ok" do
      assert :ok = BusShelter.candidate_templates()
    end
  end

  describe "candidate_instances/1" do
    test "returns ok" do
      assert :ok = BusShelter.candidate_instances(:ok)
    end
  end
end
