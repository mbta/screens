defmodule Screens.V2.WidgetInstance.SubwayStatusTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.V2.Audio
  alias Screens.Alerts.Alert
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.BusShelter
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.SubwayStatus

  defp subway_alerts(alerts),
    do: Enum.map(alerts, &%{alert: &1, context: %{all_platforms_at_informed_station: []}})

  describe "priority/1" do
    test "returns high priority for a flex zone widget" do
      instance = %SubwayStatus{subway_alerts: []}
      assert [2, 1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns normal service when there are no alerts" do
      instance = %SubwayStatus{
        subway_alerts: []
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles station closure alert with 4+ stops" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"},
                %{route: "Blue", stop: "place-mvbcl"},
                %{route: "Blue", stop: "place-aqucl"},
                %{route: "Blue", stop: "place-state"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "Bypassing 4 stops",
            location: %{
              abbrev: "mbta.com/alerts",
              full: "mbta.com/alerts"
            },
            station_count: 4
          }
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles station closure alert with 3 stops" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"},
                %{route: "Blue", stop: "place-mvbcl"},
                %{route: "Blue", stop: "place-aqucl"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "Bypassing",
            location: %{
              abbrev: "Airport, Maverick & Aquarium",
              full: "Airport, Maverick & Aquarium"
            },
            station_count: 3
          }
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"},
                %{route: "Blue", stop: "place-mvbcl"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "Bypassing",
            location: %{abbrev: "Airport and Maverick", full: "Airport and Maverick"},
            station_count: 2
          }
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts, 2 routes" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"},
                %{route: "Blue", stop: "place-mvbcl"},
                %{route: "Blue", stop: "place-aqucl"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil},
                %{route: "Green-C", stop: nil},
                %{route: "Green-D", stop: nil},
                %{route: "Green-E", stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "Suspension",
            location: %{abbrev: "Airport to Aquarium", full: "Airport to Aquarium"}
          }
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "GL", color: :green},
            status: "Delays up to 20 minutes",
            location: nil
          }
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts, 1 non-GL route" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"},
                %{route: "Blue", stop: "place-mvbcl"},
                %{route: "Blue", stop: "place-aqucl"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Suspension",
              location: %{abbrev: "Airport", full: "Airport"}
            },
            %{
              status: "Delays up to 20 minutes",
              location: %{abbrev: "Airport to Aquarium", full: "Airport to Aquarium"}
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 4 alerts, 2 non-GL routes" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"},
                %{route: "Blue", stop: "place-mvbcl"},
                %{route: "Blue", stop: "place-aqucl"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"},
                %{route: "Blue", stop: "place-mvbcl"},
                %{route: "Blue", stop: "place-aqucl"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"},
                %{route: "Orange", stop: "place-mlmnl"},
                %{route: "Orange", stop: "place-welln"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"},
                %{route: "Orange", stop: "place-mlmnl"},
                %{route: "Orange", stop: "place-welln"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "2 current alerts",
              location: "mbta.com/alerts"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "2 current alerts",
              location: "mbta.com/alerts"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 3 alerts, 2 non-GL routes" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Blue", stop: "place-aport"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"},
                %{route: "Orange", stop: "place-mlmnl"},
                %{route: "Orange", stop: "place-welln"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"},
                %{route: "Orange", stop: "place-mlmnl"},
                %{route: "Orange", stop: "place-welln"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Bypassing",
              location: %{abbrev: "Airport", full: "Airport"},
              station_count: 1
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              location: %{abbrev: "Oak Grove to Wellington", full: "Oak Grove to Wellington"},
              route_pill: %{color: :orange, text: "OL", type: :text},
              status: "Suspension"
            },
            %{
              location: %{abbrev: "Oak Grove to Wellington", full: "Oak Grove to Wellington"},
              status: "Delays up to 20 minutes"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert on GL trunk and 1 alert on GL branch" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Green-C", stop: "place-hwsst"},
                %{route: "Green-C", stop: "place-kntst"},
                %{route: "Green-C", stop: "place-stpul"}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-D", stop: "place-gover"},
                %{route: "Green-D", stop: "place-river"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              location: %{
                abbrev: "Gov't Ctr and Riverside",
                full: "Government Center and Riverside"
              },
              route_pill: %{color: :green, text: "GL", type: :text},
              station_count: 2,
              status: "Bypassing"
            },
            %{
              location: %{
                abbrev: "Hawes St to St. Paul St",
                full: "Hawes Street to Saint Paul Street"
              },
              route_pill: %{branches: [:c], color: :green, text: "GL", type: :text},
              status: "Suspension"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert on GL trunk and 2 alerts on GL branch" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Green-C", stop: "place-hwsst"},
                %{route: "Green-C", stop: "place-kntst"},
                %{route: "Green-C", stop: "place-stpul"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 6,
              informed_entities: [
                %{route: "Green-B", stop: nil},
                %{route: "Green-C", stop: nil},
                %{route: "Green-D", stop: nil},
                %{route: "Green-E", stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              location: nil,
              route_pill: %{color: :green, text: "GL", type: :text},
              status: "Delays up to 25 minutes"
            },
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:b, :c]},
              status: "2 current alerts",
              location: "mbta.com/alerts"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts on GL trunk" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Green-C", stop: "place-gover"},
                %{route: "Green-C", stop: "place-pktrm"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil},
                %{route: "Green-C", stop: nil},
                %{route: "Green-D", stop: nil},
                %{route: "Green-E", stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              location: nil,
              route_pill: %{color: :green, text: "GL", type: :text},
              status: "Delays up to 20 minutes"
            },
            %{
              location: %{
                abbrev: "Gov't Ctr to Park St",
                full: "Government Center to Park Street"
              },
              route_pill: %{color: :green, text: "GL", type: :text},
              status: "Suspension"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts on GL branches" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Green-C", stop: nil}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:b]},
              status: "Delays up to 20 minutes",
              location: nil
            },
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:c]},
              status: "Delays over 60 minutes",
              location: nil
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 3+ alerts on GL branches" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Green-C", stop: nil}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-E", stop: "place-symcl"},
                %{route: "Green-E", stop: "place-nuniv"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:b, :c, :e]},
              status: "3 current alerts",
              location: "mbta.com/alerts"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts on GL branches and 1 alert on non-GL route" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Green-C", stop: nil}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Bypassing",
              location: %{abbrev: "Oak Grove", full: "Oak Grove"},
              station_count: 1
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:b]},
              status: "Delays up to 20 minutes",
              location: nil
            },
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:c]},
              status: "Delays over 60 minutes",
              location: nil
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts on GL trunk and 1 alert on GL branch" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Green-C", stop: nil}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil},
                %{route: "Green-C", stop: nil},
                %{route: "Green-D", stop: nil},
                %{route: "Green-E", stop: nil}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-D", stop: "place-kencl"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "3 current alerts",
              location: "mbta.com/alerts"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts on GL branches and 2 alerts on non-GL route" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Green-C", stop: nil}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Green-B", stop: nil}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"}
              ]
            },
            %Alert{
              effect: :delay,
              severity: 5,
              informed_entities: [
                %{route: "Orange", stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "2 current alerts",
              location: "mbta.com/alerts"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:b]},
              status: "Delays up to 20 minutes",
              location: nil
            },
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:c]},
              status: "Delays over 60 minutes",
              location: nil
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert on GL trunk and 2 alerts on non-GL route" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-D", stop: "place-lech"},
                %{route: "Green-E", stop: "place-lech"}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Blue", stop: "place-bmmnl"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          alerts: [
            %{
              route_pill: %{color: :blue, text: "BL", type: :text},
              status: "Suspension",
              location: %{abbrev: "Beachmont", full: "Beachmont"}
            }
          ],
          type: :contracted
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              location: %{abbrev: "Oak Grove", full: "Oak Grove"},
              route_pill: %{color: :orange, text: "OL", type: :text},
              station_count: 1,
              status: "Bypassing"
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              location: %{abbrev: "Lechmere", full: "Lechmere"},
              route_pill: %{color: :green, text: "GL", type: :text},
              status: "Bypassing",
              station_count: 1
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert on GL branch and 1 alert on non-GL route" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Green-C", stop: nil}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "OL", color: :orange},
            status: "Bypassing",
            location: %{abbrev: "Oak Grove", full: "Oak Grove"},
            station_count: 1
          }
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "GL", color: :green, branches: [:c]},
            status: "Delays over 60 minutes",
            location: nil
          }
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert affecting 3 routes" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Green-C", stop: nil},
                %{route: "Blue", stop: nil},
                %{route: "Orange", stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Delays over 60 minutes",
              location: nil
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Delays over 60 minutes",
              location: nil
            }
          ]
        },
        red: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "RL", color: :red},
              status: "Normal Service"
            }
          ]
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:c]},
              status: "Delays over 60 minutes",
              location: nil
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 platform closure alert" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Red", stop: "place-portr", route_type: 1},
                %{route: "Red", stop: "70065", route_type: 1}
              ]
            },
            context: %{
              all_platforms_at_informed_station: [
                %{id: "70065", platform_name: "Ashmont/Braintree"},
                %{id: "70066", platform_name: "Alewife"}
              ]
            }
          }
        ]
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :extended,
          alert: %{
            status: "Bypassing 1 stop",
            location: %{full: "mbta.com/alerts", abbrev: "mbta.com/alerts"},
            route_pill: %{type: :text, text: "RL", color: :red}
          }
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles alert closing multiple platforms at one station" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Red", stop: "place-jfk", route_type: 1},
                %{route: "Red", stop: "70085", route_type: 1},
                %{route: "Red", stop: "70095", route_type: 1}
              ]
            },
            context: %{
              all_platforms_at_informed_station: [
                %{id: "70085", platform_name: "Ashmont"},
                %{id: "70086", platform_name: "Alewife (from Ashmont)"},
                %{id: "70095", platform_name: "Braintree"},
                %{id: "70096", platform_name: "Alewife (from Braintree)"}
              ]
            }
          }
        ]
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Normal Service"
            }
          ]
        },
        orange: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "OL", color: :orange},
              status: "Normal Service"
            }
          ]
        },
        red: %{
          type: :extended,
          alert: %{
            status: "Bypassing 2 stops",
            location: %{full: "mbta.com/alerts", abbrev: "mbta.com/alerts"},
            route_pill: %{type: :text, text: "RL", color: :red}
          }
        },
        green: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "GL", color: :green},
              status: "Normal Service"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "uses 'Entire line' location text for whole-line shuttles" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :shuttle,
              informed_entities: [
                %{route: "Blue", route_type: 1, direction_id: nil, stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "Shuttle Bus",
            location: "Entire line"
          }
        },
        green: %{
          alerts: [
            %{route_pill: %{color: :green, text: "GL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        orange: %{
          alerts: [
            %{route_pill: %{color: :orange, text: "OL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        red: %{
          alerts: [
            %{route_pill: %{color: :red, text: "RL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "uses 'Entire line' location text for whole-line suspensions" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Blue", route_type: 1, direction_id: nil, stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "SERVICE SUSPENDED",
            location: "Entire line"
          }
        },
        green: %{
          alerts: [
            %{route_pill: %{color: :green, text: "GL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        orange: %{
          alerts: [
            %{route_pill: %{color: :orange, text: "OL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        red: %{
          alerts: [
            %{route_pill: %{color: :red, text: "RL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "uses 'Entire line' location text for whole-Green Line suspensions" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Green-B", route_type: 0, direction_id: nil, stop: nil},
                %{route: "Green-C", route_type: 0, direction_id: nil, stop: nil},
                %{route: "Green-D", route_type: 0, direction_id: nil, stop: nil},
                %{route: "Green-E", route_type: 0, direction_id: nil, stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          alerts: [
            %{route_pill: %{color: :blue, text: "BL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        green: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "GL", color: :green},
            status: "SERVICE SUSPENDED",
            location: "Entire line"
          }
        },
        orange: %{
          alerts: [
            %{route_pill: %{color: :orange, text: "OL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        red: %{
          alerts: [
            %{route_pill: %{color: :red, text: "RL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "does _not_ use 'Entire line' location text for whole-line delays" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :delay,
              severity: 9,
              informed_entities: [
                %{route: "Blue", route_type: 1, direction_id: nil, stop: nil}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "Delays over 60 minutes",
            location: nil
          }
        },
        green: %{
          alerts: [
            %{route_pill: %{color: :green, text: "GL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        orange: %{
          alerts: [
            %{route_pill: %{color: :orange, text: "OL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        red: %{
          alerts: [
            %{route_pill: %{color: :red, text: "RL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "finds correct endpoints if shuttle starts on trunk" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :shuttle,
              informed_entities: [
                %{direction_id: nil, route: "Green-C", route_type: 0, stop: "place-kencl"},
                %{direction_id: nil, route: "Green-C", route_type: 0, stop: "place-smary"},
                %{direction_id: nil, route: "Green-C", route_type: 0, stop: "place-hwsst"},
                %{direction_id: nil, route: "Green-C", route_type: 0, stop: "place-kntst"}
              ]
            }
          ])
      }

      expected = %{
        blue: %{
          alerts: [
            %{route_pill: %{color: :blue, text: "BL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        green: %{
          type: :extended,
          alert: %{
            location: %{abbrev: "Kenmore to Kent St", full: "Kenmore to Kent Street"},
            route_pill: %{color: :green, text: "GL", type: :text, branches: [:c]},
            status: "Shuttle Bus"
          }
        },
        orange: %{
          alerts: [
            %{route_pill: %{color: :orange, text: "OL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        },
        red: %{
          alerts: [
            %{route_pill: %{color: :red, text: "RL", type: :text}, status: "Normal Service"}
          ],
          type: :contracted
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns medium and large flex zone" do
      instance = %SubwayStatus{subway_alerts: []}
      assert [:medium, :large] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns subway status" do
      instance = %SubwayStatus{subway_alerts: []}
      assert :subway_status == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns same result as serialize/1" do
      instance = %SubwayStatus{
        subway_alerts: []
      }

      assert WidgetInstance.serialize(instance) == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [2]" do
      instance = %SubwayStatus{}
      assert [2] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false for bus shelter screens with periodic audio" do
      instance = %SubwayStatus{
        screen:
          struct(Screen,
            app_id: :bus_shelter_v2,
            app_params: struct(BusShelter, audio: %Audio{interval_enabled: true})
          )
      }

      refute WidgetInstance.audio_valid_candidate?(instance)
    end

    test "returns true for bus shelter screens without periodic audio" do
      instance = %SubwayStatus{
        screen:
          struct(Screen,
            app_id: :bus_shelter_v2,
            app_params: struct(BusShelter, audio: %Audio{interval_enabled: false})
          )
      }

      assert WidgetInstance.audio_valid_candidate?(instance)
    end

    test "returns true for other screen types" do
      instance = %SubwayStatus{screen: struct(Screen, app_id: :pre_fare_v2)}

      assert WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns SubwayStatusView" do
      instance = %SubwayStatus{}
      assert ScreensWeb.V2.Audio.SubwayStatusView == WidgetInstance.audio_view(instance)
    end
  end
end
