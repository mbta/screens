defmodule Screens.Stops.StopTest do
  use ExUnit.Case, async: true

  alias Screens.Stops.Stop

  describe "fetch/2" do
    defp stop_data(
           id,
           attributes,
           parent_station_ref \\ nil,
           child_stop_refs \\ nil,
           connecting_stop_refs \\ nil
         ) do
      data =
        %{
          "id" => id,
          "type" => "stop",
          "attributes" =>
            Map.merge(
              %{
                "name" => "Test Stop",
                "location_type" => 0,
                "platform_code" => "",
                "platform_name" => "",
                "vehicle_type" => 3
              },
              attributes
            ),
          "relationships" => %{
            "parent_station" => %{"data" => parent_station_ref}
          }
        }

      data_child =
        if is_nil(child_stop_refs) do
          data
        else
          put_in(data, ~w[relationships child_stops], %{"data" => child_stop_refs})
        end

      if is_nil(connecting_stop_refs) do
        data_child
      else
        put_in(data_child, ~w[relationships connecting_stops], %{"data" => connecting_stop_refs})
      end
    end

    defp stop_ref(id), do: %{"id" => id, "type" => "stop"}

    test "fetches and parses stops and their parent/child relationships" do
      stop_p2 = stop_data("p2", %{"location_type" => 1}, nil, [stop_ref("c3")])
      stop_c3 = stop_data("c3", %{}, stop_ref("p2"))

      get_json_fn =
        fn "stops",
           %{
             "filter[id]" => "s1,s2,p1,p2,c3",
             "include" =>
               "child_stops,connecting_stops,parent_station.child_stops,parent_station.connecting_stops"
           } ->
          {
            :ok,
            %{
              "data" => [
                stop_data("s1", %{}),
                stop_data("s2", %{}, nil, [], [stop_ref("conn2"), stop_ref("conn3")]),
                stop_data("p1", %{"location_type" => 1}, nil, [stop_ref("c1"), stop_ref("c2")], [
                  stop_ref("conn1")
                ]),
                stop_p2,
                stop_c3
              ],
              "included" => [
                stop_data("c1", %{}, stop_ref("p1")),
                stop_data("c2", %{}, stop_ref("p1")),
                stop_data("conn1", %{}, stop_ref("p1")),
                stop_data("conn2", %{}, stop_ref("s2")),
                stop_data("conn3", %{}, stop_ref("s2")),
                stop_c3,
                stop_p2
              ]
            }
          }
        end

      assert {
               :ok,
               [
                 %Stop{
                   id: "s1",
                   location_type: 0,
                   parent_station: nil,
                   child_stops: [],
                   vehicle_type: :bus
                 },
                 %Stop{
                   id: "s2",
                   location_type: 0,
                   parent_station: nil,
                   child_stops: [],
                   connecting_stops: [
                     %Stop{id: "conn2", parent_station: :unloaded},
                     %Stop{id: "conn3", parent_station: :unloaded}
                   ],
                   vehicle_type: :bus
                 },
                 %Stop{
                   id: "p1",
                   location_type: 1,
                   parent_station: nil,
                   child_stops: [
                     %Stop{id: "c1", parent_station: :unloaded},
                     %Stop{id: "c2", parent_station: :unloaded}
                   ],
                   connecting_stops: [
                     %Stop{id: "conn1", parent_station: :unloaded}
                   ]
                 },
                 %Stop{
                   id: "p2",
                   location_type: 1,
                   parent_station: nil,
                   child_stops: [%Stop{id: "c3", parent_station: :unloaded}]
                 },
                 %Stop{
                   id: "c3",
                   parent_station: %Stop{
                     id: "p2",
                     location_type: 1,
                     parent_station: nil,
                     child_stops: [%Stop{id: "c3", parent_station: :unloaded}]
                   }
                 }
               ]
             } = Stop.fetch(%{ids: ~w[s1 s2 p1 p2 c3]}, true, get_json_fn)
    end

    test "parsing prevents connecting stops from loading more connecting stops" do
      get_json_fn =
        fn "stops",
           %{
             "filter[id]" => "s1,s2",
             "include" =>
               "child_stops,connecting_stops,parent_station.child_stops,parent_station.connecting_stops"
           } ->
          {
            :ok,
            %{
              "data" => [
                stop_data("s1", %{}, nil, [], [stop_ref("s2")]),
                stop_data("s2", %{}, nil, [], [stop_ref("s1")])
              ],
              "included" => [
                stop_data("s1", %{}, nil, [], [stop_ref("s2")]),
                stop_data("s2", %{}, nil, [], [stop_ref("s1")])
              ]
            }
          }
        end

      assert {
               :ok,
               [
                 %Stop{
                   id: "s1",
                   location_type: 0,
                   parent_station: nil,
                   child_stops: [],
                   connecting_stops: [
                     %Stop{id: "s2", parent_station: nil, connecting_stops: :unloaded}
                   ],
                   vehicle_type: :bus
                 },
                 %Stop{
                   id: "s2",
                   location_type: 0,
                   parent_station: nil,
                   child_stops: [],
                   connecting_stops: [
                     %Stop{id: "s1", parent_station: nil, connecting_stops: :unloaded}
                   ],
                   vehicle_type: :bus
                 }
               ]
             } = Stop.fetch(%{ids: ~w[s1 s2]}, true, get_json_fn)
    end
  end
end
