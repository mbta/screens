defmodule Screens.RoutePatterns.RoutePatternTest do
  use ExUnit.Case, async: true

  alias Screens.Lines.Line
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop

  describe "fetch/2" do
    test "fetches and parses route patterns" do
      get_json_fn =
        fn "route_patterns", %{"include" => "route.line,representative_trip.stops"} ->
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
                  },
                  "relationships" => %{
                    "line" => %{"data" => %{"id" => "line-Blue", "type" => "line"}}
                  }
                },
                %{
                  "id" => "line-Blue",
                  "type" => "line",
                  "attributes" => %{
                    "long_name" => "Blue Line",
                    "short_name" => "",
                    "sort_order" => 0
                  }
                },
                %{
                  "id" => "canonical-Blue-C1-0",
                  "type" => "trip",
                  "attributes" => %{"headsign" => "Bowdoin"},
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
                  "attributes" => %{"headsign" => "Bowdoin"},
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
                    "location_type" => 0,
                    "platform_code" => "1",
                    "platform_name" => "Bowdoin",
                    "vehicle_type" => 1
                  },
                  "relationships" => %{}
                },
                %{
                  "id" => "70051",
                  "type" => "stop",
                  "attributes" => %{
                    "name" => "Orient Heights",
                    "location_type" => 0,
                    "platform_code" => nil,
                    "platform_name" => "Bowdoin",
                    "vehicle_type" => 1
                  },
                  "relationships" => %{}
                },
                %{
                  "id" => "70838",
                  "type" => "stop",
                  "attributes" => %{
                    "name" => "Bowdoin",
                    "location_type" => 0,
                    "platform_code" => nil,
                    "platform_name" => "Exit Only",
                    "vehicle_type" => 1
                  },
                  "relationships" => %{}
                }
              ]
            }
          }
        end

      blue_line = %Line{
        id: "line-Blue",
        short_name: "",
        long_name: "Blue Line",
        sort_order: 0
      }

      blue_route = %Route{
        id: "Blue",
        short_name: "",
        long_name: "Blue Line",
        direction_destinations: ["Bowdoin", "Wonderland"],
        type: :subway,
        line: blue_line
      }

      bowdoin = %Stop{
        id: "70838",
        name: "Bowdoin",
        location_type: 0,
        platform_code: nil,
        platform_name: "Exit Only",
        vehicle_type: :subway,
        child_stops: [],
        connecting_stops: :unloaded
      }

      orient_heights = %Stop{
        id: "70051",
        name: "Orient Heights",
        location_type: 0,
        platform_code: nil,
        platform_name: "Bowdoin",
        vehicle_type: :subway,
        child_stops: [],
        connecting_stops: :unloaded
      }

      wonderland = %Stop{
        id: "70059",
        name: "Wonderland",
        location_type: 0,
        platform_code: "1",
        platform_name: "Bowdoin",
        vehicle_type: :subway,
        child_stops: [],
        connecting_stops: :unloaded
      }

      expected = [
        %RoutePattern{
          id: "Blue-6-0",
          canonical?: true,
          direction_id: 0,
          typicality: 1,
          route: blue_route,
          headsign: "Bowdoin",
          stops: [wonderland, bowdoin]
        },
        %RoutePattern{
          id: "Blue-8-0",
          canonical?: false,
          direction_id: 0,
          typicality: 3,
          route: blue_route,
          headsign: "Bowdoin",
          stops: [orient_heights, bowdoin]
        }
      ]

      assert {:ok, expected} == RoutePattern.fetch(%{}, get_json_fn)
    end

    test "filters by route type or typicality" do
      get_json_fn =
        fn "route_patterns", %{"include" => "route.line,representative_trip.stops"} ->
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
                  },
                  "relationships" => %{
                    "line" => %{"data" => %{"id" => "line-Blue", "type" => "line"}}
                  }
                },
                %{
                  "id" => "line-Blue",
                  "type" => "line",
                  "attributes" => %{
                    "long_name" => "Blue Line",
                    "short_name" => "",
                    "sort_order" => 0
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
                  },
                  "relationships" => %{
                    "line" => %{"data" => %{"id" => "line-1", "type" => "line"}}
                  }
                },
                %{
                  "id" => "line-1",
                  "type" => "line",
                  "attributes" => %{
                    "long_name" => "Harvard - Nubian",
                    "short_name" => "1",
                    "sort_order" => 1
                  }
                },
                %{
                  "id" => "trip-blue",
                  "type" => "trip",
                  "attributes" => %{"headsign" => "Bowdoin"},
                  "relationships" => %{"stops" => %{"data" => []}}
                },
                %{
                  "id" => "trip-bus-1",
                  "type" => "trip",
                  "attributes" => %{"headsign" => "Nubian"},
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
