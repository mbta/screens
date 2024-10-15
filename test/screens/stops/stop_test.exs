defmodule Screens.Stops.StopTest do
  use ExUnit.Case, async: true

  alias Screens.Stops.Stop

  describe "fetch_child_stops/2" do
    test "fetches the child stops of the provided stop IDs" do
      stop_attributes = %{
        "name" => "test",
        "location_type" => 0,
        "platform_code" => "",
        "platform_name" => ""
      }

      get_json_fn =
        fn "stops", %{"filter[id]" => "sX,s1,p1,p2", "include" => "child_stops"} ->
          {
            :ok,
            %{
              "data" => [
                # suppose sX doesn't exist
                %{
                  "id" => "s1",
                  "attributes" => stop_attributes,
                  "relationships" => %{"child_stops" => %{"data" => []}}
                },
                %{
                  "id" => "p1",
                  "attributes" => Map.put(stop_attributes, "location_type", 1),
                  "relationships" => %{
                    "child_stops" => %{"data" => [%{"id" => "c1"}, %{"id" => "c2"}]}
                  }
                },
                %{
                  "id" => "p2",
                  "attributes" => Map.put(stop_attributes, "location_type", 1),
                  "relationships" => %{
                    "child_stops" => %{"data" => [%{"id" => "c3"}]}
                  }
                }
              ],
              "included" => [
                %{"id" => "c1", "attributes" => stop_attributes},
                %{"id" => "c2", "attributes" => stop_attributes},
                %{"id" => "c3", "attributes" => stop_attributes}
              ]
            }
          }
        end

      assert {:ok, [[], [%Stop{id: "s1"}], [%Stop{id: "c1"}, %Stop{id: "c2"}], [%Stop{id: "c3"}]]} =
               Stop.fetch_child_stops(~w[sX s1 p1 p2], get_json_fn)
    end
  end
end
