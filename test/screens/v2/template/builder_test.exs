defmodule Screens.V2.Template.BuilderTest do
  use ExUnit.Case, async: true

  alias Screens.V2.Template.Builder

  describe "build_template/1" do
    test "flattens paged groups into containing lists" do
    end
  end

  describe "with_paging/2" do
    test "handles atom correctly" do
      draft_template = :header
      num_pages = 3

      expected = [{0, :header}, {1, :header}, {2, :header}]

      assert expected == Builder.with_paging(draft_template, num_pages)
    end

    test "handles map correctly" do
      draft_template =
        {:flex_zone,
         %{
           one_large: [:large],
           two_medium: [
             :medium_left,
             {:medium_right,
              %{
                child_slot1: [:child_a, :child_b],
                child_slot2: [:child_c]
              }}
           ]
         }}

      num_pages = 2

      expected = [
        {{0, :flex_zone},
         %{
           one_large: [{0, :large}],
           two_medium: [
             {0, :medium_left},
             {{0, :medium_right},
              %{
                child_slot1: [{0, :child_a}, {0, :child_b}],
                child_slot2: [{0, :child_c}]
              }}
           ]
         }},
        {{1, :flex_zone},
         %{
           one_large: [{1, :large}],
           two_medium: [
             {1, :medium_left},
             {{1, :medium_right},
              %{
                child_slot1: [{1, :child_a}, {1, :child_b}],
                child_slot2: [{1, :child_c}]
              }}
           ]
         }}
      ]

      assert expected == Builder.with_paging(draft_template, num_pages)
    end

    test "rejects paged templates" do
      paged_draft_template = [{0, :header}, {1, :header}]
      num_pages = 2

      assert_raise FunctionClauseError, fn ->
        Builder.with_paging(paged_draft_template, num_pages)
      end
    end

    test "rejects nested paged templates" do
      paged_draft_template =
        {:flex_zone,
         %{
           one_large: [:large],
           two_medium: [
             :medium_left,
             Builder.with_paging(
               {:medium_right,
                %{
                  child_slot1: [:child_a, :child_b],
                  child_slot2: [:child_c]
                }},
               2
             )
           ]
         }}

      num_pages = 2

      assert_raise FunctionClauseError, fn ->
        Builder.with_paging(paged_draft_template, num_pages)
      end
    end
  end
end
