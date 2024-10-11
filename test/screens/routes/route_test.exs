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
            "attributes" => %{
              "short_name" => nil,
              "long_name" => nil,
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

  describe "serving_stop_with_active/3" do
    setup do
      active_routes = response(~w[22 44])
      all_routes = response(~w[22 29 44])

      stop_id = "1265"
      now = ~U[2021-01-01T00:00:00Z]

      today_iso8601 = Date.to_iso8601(now)

      %{
        stop_id: stop_id,
        now: now,
        get_json_fn: fn
          _, %{"filter[stop]" => ^stop_id, "filter[date]" => ^today_iso8601} ->
            {:ok, active_routes}

          _, %{"filter[stop]" => ^stop_id} ->
            {:ok, all_routes}
        end,
        fetch_routes_fn: fn _, _, _ -> {:ok, []} end,
        x_get_json_fn1: fn
          _, %{"filter[stop]" => ^stop_id, "filter[date]" => ^today_iso8601} -> :error
          _, %{"filter[stop]" => ^stop_id} -> {:ok, all_routes}
        end,
        x_get_json_fn2: fn
          _, %{"filter[stop]" => ^stop_id, "filter[date]" => ^today_iso8601} ->
            {:ok, active_routes}

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
        now: now,
        get_json_fn: get_json_fn
      } = context

      expected_routes = [
        %{active?: true, route_id: "22"},
        %{active?: false, route_id: "29"},
        %{active?: true, route_id: "44"}
      ]

      assert {:ok, expected_routes} == serving_stop_with_active(stop_id, now, [], get_json_fn)
    end

    test "returns :error if either fetch function returns :error", context do
      %{
        stop_id: stop_id,
        now: now,
        get_json_fn: get_json_fn,
        x_get_json_fn1: x_get_json_fn1,
        x_get_json_fn2: x_get_json_fn2,
        x_fetch_routes_fn: x_fetch_routes_fn
      } = context

      assert :error == serving_stop_with_active(stop_id, now, [], x_get_json_fn1)
      assert :error == serving_stop_with_active(stop_id, now, [], x_get_json_fn2)
      assert :error == serving_stop_with_active(stop_id, now, [], get_json_fn, x_fetch_routes_fn)
    end

    test "filters routes by type if provided", context do
      %{
        stop_id: stop_id,
        now: now,
        fetch_routes_fn: fetch_routes_fn,
        get_json_fn: get_json_fn
      } = context

      assert {:ok, []} ==
               serving_stop_with_active(stop_id, now, :subway, get_json_fn, fetch_routes_fn)
    end
  end
end
