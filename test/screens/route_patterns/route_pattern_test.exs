defmodule Screens.RoutePatterns.RoutePatternTest do
  use ExUnit.Case, async: true

  import Screens.RoutePatterns.RoutePattern

  describe "fetch_stop_sequences_through_stop/2" do
    test "returns {:ok, sequences} if fetch function returns {:ok, data}" do
      stop_id = "1265"

      params = %{
        "include" => "representative_trip.stops,route",
        "filter[stop]" => stop_id
      }

      data = %{
        "included" => [
          %{"type" => "stop"},
          %{
            "type" => "trip",
            "relationships" => %{
              "stops" => %{"data" => [%{"id" => "1"}, %{"id" => "2"}, %{"id" => "3"}]}
            }
          },
          %{
            "type" => "trip",
            "relationships" => %{
              "stops" => %{"data" => [%{"id" => "5"}, %{"id" => "6"}, %{"id" => "7"}]}
            }
          }
        ]
      }

      get_json_fn = fn _, ^params -> {:ok, data} end

      expected_stop_sequences = [~w[1 2 3], ~w[5 6 7]]

      assert {:ok, expected_stop_sequences} ==
               fetch_stop_sequences_through_stop(stop_id, [], get_json_fn)
    end

    test "returns :error if fetch function returns :error" do
      stop_id = "1265"

      get_json_fn = fn _, _ -> :error end

      assert :error == fetch_stop_sequences_through_stop(stop_id, [], get_json_fn)
    end

    test "returns filtered list if route_filters is provided" do
      stop_id = "1265"
      route_filters = ["Orange"]

      params = %{
        "include" => "representative_trip.stops,route",
        "filter[stop]" => stop_id,
        "filter[route]" => Enum.join(route_filters, ",")
      }

      data = %{
        "included" => [
          %{
            "type" => "trip",
            "relationships" => %{
              "stops" => %{"data" => [%{"id" => "5"}, %{"id" => "6"}, %{"id" => "7"}]},
              "route" => %{"data" => %{"id" => "Orange"}}
            }
          }
        ]
      }

      get_json_fn = fn _, ^params -> {:ok, data} end

      expected_stop_sequences = [~w[5 6 7]]

      assert {:ok, expected_stop_sequences} ==
               fetch_stop_sequences_through_stop(stop_id, route_filters, get_json_fn)
    end
  end
end
