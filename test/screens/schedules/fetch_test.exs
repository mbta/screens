defmodule Screens.Schedules.FetchTest do
  use ExUnit.Case, async: true

  alias Screens.Schedules.Fetch
  alias Screens.Schedules.Schedule
  alias Screens.Schedules.Store

  @include "route.line,stop,trip.route_pattern.representative_trip,trip.stops"

  test "requests the explicit service date and preserves filters and includes" do
    params = %{
      stop_ids: ["70001", "70003"],
      route_ids: ["Orange"],
      direction_id: 1,
      mode: :ol,
      sort: "departure_time",
      date: ~D[2000-01-01],
      include: ["predictions"]
    }

    get_json = fn "schedules", encoded ->
      assert encoded == %{
               "filter[date]" => "2024-10-11",
               "filter[stop]" => "70001,70003",
               "filter[route]" => "Orange",
               "filter[direction_id]" => 1,
               "filter[route_type]" => 1,
               "sort" => "departure_time",
               "include" => @include
             }

      {:ok, %{"data" => []}}
    end

    assert {:ok, []} = Fetch.fetch(params, ~D[2024-10-11], get_json)
  end

  test "parses schedules and filters arrival-only records without dropping past departures" do
    response = response()
    get_json = fn "schedules", _ -> {:ok, response} end

    assert {:ok, [%Schedule{} = schedule]} = Fetch.fetch(%{}, ~D[2024-10-11], get_json)
    assert schedule.id == "departure"
    assert schedule.departure_time == ~U[2024-10-12 05:00:00Z]
    assert schedule.arrival_time == ~U[2024-10-12 04:59:00Z]
    assert schedule.stop.id == "platform"
    assert schedule.track_number == "1"
    assert schedule.direction_id == 1
  end

  test "normalizes acquisition failures to the existing error result" do
    for failure <- [{:error, :unavailable}, :error] do
      assert :error = Fetch.fetch(%{}, ~D[2024-10-11], fn _, _ -> failure end)
    end
  end

  test "Schedule.fetch/2 reads parsed datasets without an API request" do
    stop_id = inspect(make_ref())
    params = %{stop_ids: [stop_id]}
    date = ~D[2024-10-11]
    {:ok, schedules} = Fetch.fetch(params, date, fn _, _ -> {:ok, response()} end)

    assert {:ok, _} =
             Store.fetch_dataset(params, date,
               acquire_fn: fn _, _, _ -> {:ok, schedules, nil} end
             )

    on_exit(fn -> Store.Cache.delete(Store.key(params, date)) end)

    assert {:ok, [%Schedule{id: "departure"}]} =
             Schedule.fetch(params, date)
  end

  test "loads all pages without sending credentials to next link hosts" do
    request = fn "schedules", params, nil ->
      if params["page[offset]"] == "2" do
        {:ok, %{"data" => []}, "page-2"}
      else
        assert params["filter[date]"] == "2024-10-11"

        {:ok,
         Map.put(response(), "links", %{"next" => "https://other-host/schedules?page[offset]=2"}),
         "page-1"}
      end
    end

    date = ~D[2024-10-11]
    assert {:ok, [%Schedule{id: "departure"}], nil} = Fetch.acquire(%{}, date, nil, request)
  end

  test "does not return partial schedules when a later page fails" do
    request = fn _, params, _ ->
      if params["page[offset]"] do
        {:error, :unavailable}
      else
        {:ok, Map.put(response(), "links", %{"next" => "?page[offset]=2"}), nil}
      end
    end

    assert :error = Fetch.acquire(%{}, ~D[2024-10-11], nil, request)
  end

  test "accepts conditional revalidation only with a prior validator" do
    request = fn _, _, _ -> :not_modified end
    assert :not_modified = Fetch.acquire(%{}, ~D[2024-10-11], "modified", request)
    assert :error = Fetch.acquire(%{}, ~D[2024-10-11], nil, request)
  end

  test "rejects pagination cycles without returning partial data" do
    request = fn _, _, _ ->
      {:ok, Map.put(response(), "links", %{"next" => "?page[offset]=2"}), nil}
    end

    assert :error = Fetch.acquire(%{}, ~D[2024-10-11], nil, request)
  end

  @tag :capture_log
  test "malformed responses are acquisition errors" do
    request = fn _, _, _ -> {:ok, %{"data" => [%{"type" => "schedule"}]}, nil} end
    assert :error = Fetch.acquire(%{}, ~D[2024-10-11], nil, request)
  end

  defp response do
    %{
      "data" => [
        schedule_resource("departure", "2024-10-12T01:00:00-04:00"),
        schedule_resource("arrival-only", nil)
      ],
      "included" => [
        %{
          "type" => "stop",
          "id" => "platform",
          "attributes" => %{
            "name" => "Platform",
            "location_type" => 0,
            "platform_code" => "1",
            "platform_name" => nil,
            "vehicle_type" => 1
          },
          "relationships" => %{}
        }
      ]
    }
  end

  defp schedule_resource(id, departure_time) do
    %{
      "type" => "schedule",
      "id" => id,
      "attributes" => %{
        "arrival_time" => "2024-10-12T00:59:00-04:00",
        "departure_time" => departure_time,
        "stop_headsign" => nil,
        "direction_id" => 1
      },
      "relationships" => %{
        "stop" => %{"data" => %{"type" => "stop", "id" => "platform"}},
        "trip" => %{"data" => nil},
        "route" => %{"data" => nil}
      }
    }
  end
end
