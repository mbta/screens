defmodule Screens.V2.ScreenData.QueryParamsTest do
  use ExUnit.Case, async: true
  alias Screens.V2.ScreenData.QueryParams
  alias Plug.Conn

  defp build_conn(params) do
    %Conn{query_params: params}
  end

  describe "get_url_param_map/1" do
    test "Returns empty struct when no query params are provided" do
      conn = build_conn(%{})
      assert QueryParams.get_url_param_map(conn) == %QueryParams{}
    end

    test "Retruns QueryParam struct when valid key/value params passed in" do
      conn = build_conn(%{"route_id" => "123", "stop_id" => "456", "trip_id" => "789"})

      assert QueryParams.get_url_param_map(conn) == %QueryParams{
               route_id: "123",
               stop_id: "456",
               trip_id: "789"
             }
    end

    test "Ignores invalid query parameter keys" do
      conn = build_conn(%{"invalid_key" => "999"})
      assert QueryParams.get_url_param_map(conn) == %QueryParams{}
    end

    test "Handles mixed valid and invalid parameter keys together" do
      conn = build_conn(%{"stop_id" => "456", "another_invalid_key" => "not_used"})
      assert QueryParams.get_url_param_map(conn) == %QueryParams{stop_id: "456"}
    end

    test "Excludes params with empty/nil string values, includes valid " do
      conn = build_conn(%{"route_id" => "", "stop_id" => "456", "trip_id" => nil})
      assert QueryParams.get_url_param_map(conn) == %QueryParams{stop_id: "456"}
    end
  end

  describe "get_url_param_list/1" do
    test "Returns an empty list when no query params are provided" do
      conn = build_conn(%{})
      assert QueryParams.get_url_param_list(conn) == []
    end

    test "Returns a list of tuples when given only valid, non-nil values" do
      conn = build_conn(%{"route_id" => "123", "stop_id" => "456", "trip_id" => "trip_abcd"})

      assert QueryParams.get_url_param_list(conn) == [
               {:route_id, "123"},
               {:stop_id, "456"},
               {:trip_id, "trip_abcd"}
             ]
    end

    test "Filters out invalid param keys from the tuple list" do
      conn = build_conn(%{"route_id" => "123", "stop_id" => "", "trip_id" => nil})
      assert QueryParams.get_url_param_list(conn) == [{:route_id, "123"}]
    end

    test "Filters out nil and empty string values from the tuple list" do
      conn = build_conn(%{"route_id" => "123", "stop_id" => "", "trip_id" => nil})
      assert QueryParams.get_url_param_list(conn) == [{:route_id, "123"}]
    end

    test "Processes a mix of valid and invalid param keys/values correctly" do
      conn =
        build_conn(%{"stop_id" => "456", "route_id" => "", "invalid_param_key" => "not_used"})
      assert QueryParams.get_url_param_list(conn) == [{:stop_id, "456"}]
    end
  end
end
