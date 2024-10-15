defmodule Screens.RoutePatterns.RoutePatternTest do
  use ExUnit.Case, async: true

  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop

  describe "fetch/2" do
    test "fetches and parses route patterns" do
      get_json_fn =
        fn "route_patterns", %{"include" => "route,representative_trip.stops"} ->
          {
            :ok,
            %{
              "data" => [
                %{
                  "id" => "Blue-6-0",
                  "attributes" => %{
                    "canonical" => true,
                    "direction_id" => 0,
                    "typicality" => 1
                  },
                  "relationships" => %{
                    "representative_trip" => %{
                      "data" => %{"id" => "canonical-Blue-C1-0", "type" => "trip"}
                    },
                    "route" => %{"data" => %{"id" => "Blue", "type" => "route"}}
                  }
                },
                %{
                  "id" => "Blue-8-0",
                  "attributes" => %{
                    "canonical" => false,
                    "direction_id" => 0,
                    "typicality" => 3
                  },
                  "relationships" => %{
                    "representative_trip" => %{
                      "data" => %{"id" => "65198154", "type" => "trip"}
                    },
                    "route" => %{"data" => %{"id" => "Blue", "type" => "route"}}
                  }
                }
              ],
              "included" => [
                %{
                  "id" => "Blue",
                  "type" => "route",
                  "attributes" => %{
                    "direction_destinations" => ["Bowdoin", "Wonderland"],
                    "long_name" => "Blue Line",
                    "short_name" => "",
                    "type" => 1
                  }
                },
                %{
                  "id" => "canonical-Blue-C1-0",
                  "type" => "trip",
                  "relationships" => %{
                    "stops" => %{
                      "data" => [
                        %{"id" => "70059", "type" => "stop"},
                        %{"id" => "70838", "type" => "stop"}
                      ]
                    }
                  }
                },
                %{
                  "id" => "65198154",
                  "type" => "trip",
                  "relationships" => %{
                    "stops" => %{
                      "data" => [
                        %{"id" => "70051", "type" => "stop"},
                        %{"id" => "70838", "type" => "stop"}
                      ]
                    }
                  }
                },
                %{
                  "id" => "70059",
                  "type" => "stop",
                  "attributes" => %{
                    "name" => "Wonderland",
                    "platform_code" => "1",
                    "platform_name" => "Bowdoin"
                  }
                },
                %{
                  "id" => "70051",
                  "type" => "stop",
                  "attributes" => %{
                    "name" => "Orient Heights",
                    "platform_code" => nil,
                    "platform_name" => "Bowdoin"
                  }
                },
                %{
                  "id" => "70838",
                  "type" => "stop",
                  "attributes" => %{
                    "name" => "Bowdoin",
                    "platform_code" => nil,
                    "platform_name" => "Exit Only"
                  }
                }
              ]
            }
          }
        end

      blue_route = %Route{
        id: "Blue",
        short_name: "",
        long_name: "Blue Line",
        direction_destinations: ["Bowdoin", "Wonderland"],
        type: :subway
      }

      bowdoin = %Stop{
        id: "70838",
        name: "Bowdoin",
        platform_code: nil,
        platform_name: "Exit Only"
      }

      orient_heights = %Stop{
        id: "70051",
        name: "Orient Heights",
        platform_code: nil,
        platform_name: "Bowdoin"
      }

      wonderland = %Stop{
        id: "70059",
        name: "Wonderland",
        platform_code: "1",
        platform_name: "Bowdoin"
      }

      expected = [
        %RoutePattern{
          id: "Blue-6-0",
          canonical?: true,
          direction_id: 0,
          typicality: 1,
          route: blue_route,
          stops: [wonderland, bowdoin]
        },
        %RoutePattern{
          id: "Blue-8-0",
          canonical?: false,
          direction_id: 0,
          typicality: 3,
          route: blue_route,
          stops: [orient_heights, bowdoin]
        }
      ]

      assert {:ok, expected} == RoutePattern.fetch(%{}, get_json_fn)
    end

    test "filters by route type or typicality" do
      get_json_fn =
        fn "route_patterns", %{"include" => "route,representative_trip.stops"} ->
          {
            :ok,
            %{
              "data" => [
                %{
                  "id" => "rp-blue",
                  "attributes" => %{
                    "canonical" => true,
                    "direction_id" => 0,
                    "typicality" => 1
                  },
                  "relationships" => %{
                    "representative_trip" => %{
                      "data" => %{"id" => "trip-blue", "type" => "trip"}
                    },
                    "route" => %{"data" => %{"id" => "Blue", "type" => "route"}}
                  }
                },
                %{
                  "id" => "rp-bus-1",
                  "attributes" => %{
                    "canonical" => false,
                    "direction_id" => 0,
                    "typicality" => 3
                  },
                  "relationships" => %{
                    "representative_trip" => %{
                      "data" => %{"id" => "trip-bus-1", "type" => "trip"}
                    },
                    "route" => %{"data" => %{"id" => "1", "type" => "route"}}
                  }
                }
              ],
              "included" => [
                %{
                  "id" => "Blue",
                  "type" => "route",
                  "attributes" => %{
                    "direction_destinations" => ["Bowdoin", "Wonderland"],
                    "long_name" => "Blue Line",
                    "short_name" => "",
                    "type" => 1
                  }
                },
                %{
                  "id" => "1",
                  "type" => "route",
                  "attributes" => %{
                    "direction_destinations" => ["Harvard Square", "Nubian Station"],
                    "long_name" => "Harvard Square - Nubian Station",
                    "short_name" => "1",
                    "type" => 3
                  }
                },
                %{
                  "id" => "trip-blue",
                  "type" => "trip",
                  "relationships" => %{"stops" => %{"data" => []}}
                },
                %{
                  "id" => "trip-bus-1",
                  "type" => "trip",
                  "relationships" => %{"stops" => %{"data" => []}}
                }
              ]
            }
          }
        end

      assert {:ok, [%RoutePattern{id: "rp-bus-1"}]} =
               RoutePattern.fetch(%{route_type: :bus}, get_json_fn)

      assert {:ok, [%RoutePattern{id: "rp-blue"}]} =
               RoutePattern.fetch(%{typicality: 1}, get_json_fn)
    end
  end

  describe "fetch_tagged_stop_sequences_through_stop/2" do
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
              "stops" => %{"data" => [%{"id" => "1"}, %{"id" => "2"}, %{"id" => "3"}]},
              "route" => %{"data" => %{"id" => "route1"}}
            }
          },
          %{
            "type" => "trip",
            "relationships" => %{
              "stops" => %{"data" => [%{"id" => "3"}, %{"id" => "2"}, %{"id" => "1"}]},
              "route" => %{"data" => %{"id" => "route1"}}
            }
          },
          %{
            "type" => "trip",
            "relationships" => %{
              "stops" => %{"data" => [%{"id" => "5"}, %{"id" => "6"}, %{"id" => "7"}]},
              "route" => %{"data" => %{"id" => "route2"}}
            }
          }
        ]
      }

      get_json_fn = fn _, ^params -> {:ok, data} end

      expected_stop_sequences = %{"route1" => [~w[1 2 3], ~w[3 2 1]], "route2" => [~w[5 6 7]]}

      assert {:ok, expected_stop_sequences} ==
               RoutePattern.fetch_tagged_stop_sequences_through_stop(stop_id, [], get_json_fn)
    end

    test "returns :error if fetch function returns :error" do
      stop_id = "1265"

      get_json_fn = fn _, _ -> :error end

      assert :error ==
               RoutePattern.fetch_tagged_stop_sequences_through_stop(stop_id, [], get_json_fn)
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

      expected_stop_sequences = %{"Orange" => [~w[5 6 7]]}

      assert {:ok, expected_stop_sequences} ==
               RoutePattern.fetch_tagged_stop_sequences_through_stop(
                 stop_id,
                 route_filters,
                 get_json_fn
               )
    end
  end
end
