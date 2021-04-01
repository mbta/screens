defmodule Screens.V2.CandidateGenerator.SolariTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.Solari

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header_normal, :main_content_normal],
                overhead: [:header_overhead, :main_content_overhead],
                takeover: [:full_screen]
              }} == Solari.screen_template()
    end
  end
end
