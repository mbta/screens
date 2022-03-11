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

  describe "fetch_simplified_routes_at_stop/3" do
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
        fetch_all_route_ids_fn: fn
          _, _, :subway -> {:ok, []}
          _, _, _ -> {:ok, [route_json("22"), route_json("29"), route_json("44")]}
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
        end,
        x_fetch_all_route_ids_fn: fn
          _, _, _ -> :error
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

      assert {:ok, expected_routes} ==
               fetch_simplified_routes_at_stop(stop_id, today, get_json_fn)
    end

    test "returns :error if either fetch function returns :error", context do
      %{
        stop_id: stop_id,
        today: today,
        get_json_fn: get_json_fn,
        x_get_json_fn1: x_get_json_fn1,
        x_get_json_fn2: x_get_json_fn2,
        x_fetch_all_route_ids_fn: x_fetch_all_route_ids_fn
      } = context

      assert :error == fetch_simplified_routes_at_stop(stop_id, today, x_get_json_fn1)

      assert :error == fetch_simplified_routes_at_stop(stop_id, today, x_get_json_fn2)
    end
  end

  describe "fetch_routes_by_stop/3" do
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
        fetch_routes_fn: fn
          _, _, :subway -> {:ok, []}
          _, _, _ -> {:ok, [route_json("22"), route_json("29"), route_json("44")]}
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
        end,
        x_fetch_routes_fn: fn
          _, _, _ -> :error
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
        %{
          active?: true,
          route_id: "22",
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :subway
        },
        %{
          active?: false,
          route_id: "29",
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :subway
        },
        %{
          active?: true,
          route_id: "44",
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :subway
        }
      ]

      assert {:ok, expected_routes} == fetch_routes_by_stop(stop_id, today, [], get_json_fn)
    end

    test "returns :error if either fetch function returns :error", context do
      %{
        stop_id: stop_id,
        today: today,
        get_json_fn: get_json_fn,
        x_get_json_fn1: x_get_json_fn1,
        x_get_json_fn2: x_get_json_fn2,
        x_fetch_routes_fn: x_fetch_routes_fn
      } = context

      assert :error == fetch_routes_by_stop(stop_id, today, [], x_get_json_fn1)

      assert :error == fetch_routes_by_stop(stop_id, today, [], x_get_json_fn2)

      assert :error ==
               fetch_routes_by_stop(stop_id, today, [], get_json_fn, x_fetch_routes_fn)
    end

    test "filters routes by type if provided", context do
      %{
        stop_id: stop_id,
        today: today,
        fetch_routes_fn: fetch_routes_fn,
        get_json_fn: get_json_fn
      } = context

      assert {:ok, []} ==
               fetch_routes_by_stop(stop_id, today, :subway, get_json_fn, fetch_routes_fn)
    end
  end
end
