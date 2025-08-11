defmodule Screens.Routes.RouteTest do
  use ExUnit.Case, async: true

  import Screens.Routes.Route

  defp response(ids) do
    %{
      "data" =>
        Enum.map(
          ids,
          &%{
            "id" => &1,
            "type" => "route",
            "attributes" => %{
              "short_name" => nil,
              "long_name" => nil,
              "direction_names" => nil,
              "direction_destinations" => nil,
              "type" => 1
            },
            "relationships" => %{"line" => %{"data" => %{"id" => "line-#{&1}", "type" => "line"}}}
          }
        ),
      "included" =>
        Enum.map(
          ids,
          &%{
            "id" => "line-#{&1}",
            "type" => "line",
            "attributes" => %{
              "short_name" => nil,
              "long_name" => nil,
              "sort_order" => 0
            }
          }
        )
    }
  end

  describe "fetch/1" do
    test "sets an ID filter" do
      get_json_fn = fn _, %{"filter[id]" => "1,2,3"} -> {:ok, response(~w[2])} end

      assert {:ok, [%{id: "2"}]} = fetch(%{ids: ["1", "2", "3"]}, get_json_fn)
    end

    test "sets a limit param" do
      get_json_fn = fn _, %{"page[limit]" => "1"} -> {:ok, response(~w[ABC])} end

      assert {:ok, [%{id: "ABC"}]} = fetch(%{limit: 1}, get_json_fn)
    end
  end
end
