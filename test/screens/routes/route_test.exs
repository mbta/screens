defmodule Screens.Routes.RouteTest do
  use ExUnit.Case, async: true

  import Screens.Routes.Route

  defp route_json(id) do
    %{
      "id" => id,
      "attributes" => %{
        "short_name" => nil,
        "long_name" => nil,
        "direction_destinations" => nil,
        "type" => 1
      }
    }
  end

  describe "fetch_routes_at_stop/3" do
    setup do
      active_routes = [route_json("22"), route_json("44")]

      all_routes = [route_json("22"), route_json("29"), route_json("44")]

      stop_id = "1265"
      today = ~D[2021-01-01]

      today_iso8601 = Date.to_iso8601(today)

      %{
        stop_id: stop_id,
        today: today,
        get_json_fn: fn
          _, %{"filter[stop]" => ^stop_id, "filter[date]" => ^today_iso8601} ->
            {:ok, %{"data" => active_routes}}

          _, %{"filter[stop]" => ^stop_id} ->
            {:ok, %{"data" => all_routes}}
        end,
        x_get_json_fn1: fn
          _, %{"filter[stop]" => ^stop_id, "filter[date]" => ^today_iso8601} -> :error
          _, %{"filter[stop]" => ^stop_id} -> {:ok, %{"data" => all_routes}}
        end,
        x_get_json_fn2: fn
          _, %{"filter[stop]" => ^stop_id, "filter[date]" => ^today_iso8601} ->
            {:ok, %{"data" => active_routes}}

          _, %{"filter[stop]" => ^stop_id} ->
            :error
        end
      }
    end

    test "returns {:ok, routes} when requests succeed", context do
      %{
        stop_id: stop_id,
        today: today,
        get_json_fn: get_json_fn
      } = context

      expected_routes = [
        %{route_id: "22", active?: true},
        %{route_id: "29", active?: false},
        %{route_id: "44", active?: true}
      ]

      assert {:ok, expected_routes} == fetch_routes_at_stop(stop_id, today, get_json_fn)
    end

    test "returns :error if either fetch function returns :error", context do
      %{
        stop_id: stop_id,
        today: today,
        x_get_json_fn1: x_get_json_fn1,
        x_get_json_fn2: x_get_json_fn2
      } = context

      assert :error == fetch_routes_at_stop(stop_id, today, x_get_json_fn1)

      assert :error == fetch_routes_at_stop(stop_id, today, x_get_json_fn2)
    end
  end
end
