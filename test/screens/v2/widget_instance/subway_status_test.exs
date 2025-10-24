defmodule Screens.V2.WidgetInstance.SubwayStatusTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.SubwayStatus
  alias ScreensConfig.{Audio, Screen}
  alias ScreensConfig.Screen.BusShelter

  defp subway_alerts(alerts),
    do: Enum.map(alerts, &%{alert: &1, context: %{all_platforms_at_informed_stations: []}})

  describe "priority/1" do
    test "returns high priority for a flex zone widget" do
      instance = %SubwayStatus{subway_alerts: []}
      assert [2, 1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    @bl_pill %{type: :text, text: "BL", color: :blue}
    @gl_pill %{type: :text, text: "GL", color: :green}
    @ol_pill %{type: :text, text: "OL", color: :orange}
    @rl_pill %{type: :text, text: "RL", color: :red}
    @rl_pill_mattapan %{type: :text, text: "RL", color: :red, branches: [:m]}

    @normal_service %{
      blue: %{type: :contracted, alerts: [%{route_pill: @bl_pill, status: "Normal Service"}]},
      green: %{type: :contracted, alerts: [%{route_pill: @gl_pill, status: "Normal Service"}]},
      orange: %{type: :contracted, alerts: [%{route_pill: @ol_pill, status: "Normal Service"}]},
      red: %{type: :contracted, alerts: [%{route_pill: @rl_pill, status: "Normal Service"}]}
    }

    defp gl_pill(branches), do: Map.put(@gl_pill, :branches, branches)

    test "returns normal service when there are no alerts" do
      instance = %SubwayStatus{subway_alerts: []}

      assert @normal_service == WidgetInstance.serialize(instance)
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
        @normal_service
        | blue: %{
            type: :extended,
            alert: %{
              route_pill: @bl_pill,
              status: "4 Stops Skipped",
              location: %{abbrev: "mbta.com/alerts", full: "mbta.com/alerts"},
              station_count: 4
            }
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
        @normal_service
        | blue: %{
            type: :extended,
            alert: %{
              route_pill: @bl_pill,
              status: "3 Stops Skipped",
              location: %{
                abbrev: "mbta.com/alerts",
                full: "Airport, Maverick, and Aquarium"
              },
              station_count: 3
            }
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
        @normal_service
        | blue: %{
            type: :extended,
            alert: %{
              route_pill: @bl_pill,
              status: "2 Stops Skipped",
              location: %{abbrev: "Airport and Maverick", full: "Airport and Maverick"},
              station_count: 2
            }
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
        @normal_service
        | blue: %{
            type: :extended,
            alert: %{
              route_pill: @bl_pill,
              status: "Suspension",
              location: %{abbrev: "Airport ↔ Aquarium", full: "Airport ↔ Aquarium"}
            }
          },
          green: %{
            type: :extended,
            alert: %{route_pill: @gl_pill, status: "Delays up to 20 minutes", location: nil}
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
        @normal_service
        | blue: %{
            type: :contracted,
            alerts: [
              %{
                route_pill: @bl_pill,
                status: "Suspension",
                location: %{abbrev: "Airport", full: "Airport"}
              },
              %{
                status: "Delays up to 20 minutes",
                location: %{abbrev: "Airport ↔ Aquarium", full: "Airport ↔ Aquarium"}
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
        @normal_service
        | blue: %{
            type: :contracted,
            alerts: [
              %{route_pill: @bl_pill, status: "2 current alerts", location: "mbta.com/alerts"}
            ]
          },
          orange: %{
            type: :contracted,
            alerts: [
              %{route_pill: @ol_pill, status: "2 current alerts", location: "mbta.com/alerts"}
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
        @normal_service
        | blue: %{
            type: :contracted,
            alerts: [
              %{
                route_pill: @bl_pill,
                status: "Stop Skipped",
                location: %{abbrev: "Airport", full: "Airport"},
                station_count: 1
              }
            ]
          },
          orange: %{
            type: :contracted,
            alerts: [
              %{
                location: %{abbrev: "Oak Grove ↔ Wellington", full: "Oak Grove ↔ Wellington"},
                route_pill: @ol_pill,
                status: "Suspension"
              },
              %{
                location: %{abbrev: "Oak Grove ↔ Wellington", full: "Oak Grove ↔ Wellington"},
                status: "Delays up to 20 minutes"
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
        @normal_service
        | green: %{
            type: :contracted,
            alerts: [
              %{
                location: %{
                  abbrev: "Gov't Ctr and Riverside",
                  full: "Government Center and Riverside"
                },
                route_pill: @gl_pill,
                station_count: 2,
                status: "2 Stops Skipped"
              },
              %{
                location: %{
                  abbrev: "Hawes St ↔ St. Paul St",
                  full: "Hawes Street ↔ Saint Paul Street"
                },
                route_pill: gl_pill([:c]),
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
        @normal_service
        | green: %{
            type: :contracted,
            alerts: [
              %{location: nil, route_pill: @gl_pill, status: "Delays up to 25 minutes"},
              %{
                route_pill: gl_pill([:b, :c]),
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
        @normal_service
        | green: %{
            type: :contracted,
            alerts: [
              %{location: nil, route_pill: @gl_pill, status: "Delays up to 20 minutes"},
              %{
                location: %{
                  abbrev: "Gov't Ctr ↔ Park St",
                  full: "Government Center ↔ Park Street"
                },
                route_pill: @gl_pill,
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
        @normal_service
        | green: %{
            type: :contracted,
            alerts: [
              %{route_pill: gl_pill([:b]), status: "Delays up to 20 minutes", location: nil},
              %{route_pill: gl_pill([:c]), status: "Delays over 60 minutes", location: nil}
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
        @normal_service
        | green: %{
            type: :contracted,
            alerts: [
              %{
                route_pill: gl_pill([:b, :c, :e]),
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
        @normal_service
        | orange: %{
            type: :contracted,
            alerts: [
              %{
                route_pill: @ol_pill,
                status: "Stop Skipped",
                location: %{abbrev: "Oak Grove", full: "Oak Grove"},
                station_count: 1
              }
            ]
          },
          green: %{
            type: :contracted,
            alerts: [
              %{route_pill: gl_pill([:b]), status: "Delays up to 20 minutes", location: nil},
              %{route_pill: gl_pill([:c]), status: "Delays over 60 minutes", location: nil}
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
        @normal_service
        | green: %{
            type: :contracted,
            alerts: [
              %{route_pill: @gl_pill, status: "3 current alerts", location: "mbta.com/alerts"}
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
        @normal_service
        | orange: %{
            type: :contracted,
            alerts: [
              %{
                route_pill: @ol_pill,
                status: "2 current alerts",
                location: "mbta.com/alerts"
              }
            ]
          },
          green: %{
            type: :contracted,
            alerts: [
              %{route_pill: gl_pill([:b]), status: "Delays up to 20 minutes", location: nil},
              %{route_pill: gl_pill([:c]), status: "Delays over 60 minutes", location: nil}
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
        @normal_service
        | blue: %{
            alerts: [
              %{
                route_pill: @bl_pill,
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
                route_pill: @ol_pill,
                station_count: 1,
                status: "Stop Skipped"
              }
            ]
          },
          green: %{
            type: :contracted,
            alerts: [
              %{
                location: %{abbrev: "Lechmere", full: "Lechmere"},
                route_pill: @gl_pill,
                status: "Stop Skipped",
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
        @normal_service
        | orange: %{
            type: :extended,
            alert: %{
              route_pill: @ol_pill,
              status: "Stop Skipped",
              location: %{abbrev: "Oak Grove", full: "Oak Grove"},
              station_count: 1
            }
          },
          green: %{
            type: :extended,
            alert: %{route_pill: gl_pill([:c]), status: "Delays over 60 minutes", location: nil}
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
        @normal_service
        | blue: %{
            type: :contracted,
            alerts: [%{route_pill: @bl_pill, status: "Delays over 60 minutes", location: nil}]
          },
          orange: %{
            type: :contracted,
            alerts: [%{route_pill: @ol_pill, status: "Delays over 60 minutes", location: nil}]
          },
          green: %{
            type: :contracted,
            alerts: [
              %{route_pill: gl_pill([:c]), status: "Delays over 60 minutes", location: nil}
            ]
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert on RL and 1 alert on Mattapan" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-cenav"}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Red", stop: "place-portr"}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :contracted,
            alerts: [
              %{
                location: %{
                  abbrev: "Porter",
                  full: "Porter"
                },
                route_pill: @rl_pill,
                status: "Stop Skipped",
                station_count: 1
              },
              %{
                location: %{
                  abbrev: "Central Ave",
                  full: "Central Avenue"
                },
                route_pill: @rl_pill_mattapan,
                status: "Suspension"
              }
            ]
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles no alerts on RL and 1 alert on Mattapan" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-valrd"},
                %{route: "Mattapan", stop: "place-capst"}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :extended,
            alert: %{
              location: %{
                abbrev: "Valley Rd ↔ Capen St",
                full: "Valley Road ↔ Capen Street"
              },
              route_pill: @rl_pill_mattapan,
              status: "Suspension"
            }
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles multiple alerts on Mattapan" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-valrd"},
                %{route: "Mattapan", stop: "place-capst"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-cenav"}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :contracted,
            alerts: [
              %{
                status: "Suspension",
                location: %{full: "Valley Road ↔ Capen Street", abbrev: "Valley Rd ↔ Capen St"},
                route_pill: %{type: :text, text: "RL", color: :red, branches: [:m]}
              },
              %{
                status: "Suspension",
                location: %{full: "Central Avenue", abbrev: "Central Ave"},
                route_pill: %{type: :text, text: "RL", color: :red, branches: [:m]}
              }
            ]
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles RL alert and multiple alerts on Mattapan" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Red", stop: "place-portr"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-valrd"},
                %{route: "Mattapan", stop: "place-capst"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-cenav"}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :contracted,
            alerts: [
              %{
                location: %{abbrev: "Porter", full: "Porter"},
                route_pill: %{color: :red, text: "RL", type: :text},
                status: "Stop Skipped",
                station_count: 1
              },
              %{
                location: "mbta.com/alerts",
                route_pill: %{branches: [:m], color: :red, text: "RL", type: :text},
                status: "2 current alerts"
              }
            ]
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles multiple RL alerts and multiple alerts on Mattapan" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Red", stop: "place-portr"}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Red", stop: "place-chmnl"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-valrd"},
                %{route: "Mattapan", stop: "place-capst"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-cenav"}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :contracted,
            alerts: [
              %{
                location: "mbta.com/alerts",
                route_pill: %{color: :red, text: "RL", type: :text},
                status: "2 current alerts"
              },
              %{
                location: "mbta.com/alerts",
                route_pill: %{branches: [:m], color: :red, text: "RL", type: :text},
                status: "2 current alerts"
              }
            ]
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "consolidates two Mattapan alerts to single row when multiple GL alerts" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-D", stop: "place-lech"}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-B", stop: "place-brico"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-valrd"},
                %{route: "Mattapan", stop: "place-capst"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-cenav"}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :contracted,
            alerts: [
              %{
                location: "mbta.com/alerts",
                route_pill: %{branches: [:m], color: :red, text: "RL", type: :text},
                status: "2 current alerts"
              }
            ]
          },
          green: %{
            alerts: [
              %{
                route_pill: %{color: :green, text: "GL", type: :text},
                status: "Stop Skipped",
                location: %{full: "Lechmere", abbrev: "Lechmere"},
                station_count: 1
              },
              %{
                status: "Stop Skipped",
                location: %{full: "Packards Corner", abbrev: "Packards Cn"},
                route_pill: %{type: :text, text: "GL", color: :green, branches: [:b]},
                station_count: 1
              }
            ],
            type: :contracted
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "consolidates RL and Mattapan alert to single row when multiple GL alerts" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-D", stop: "place-lech"}
              ]
            },
            %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-B", stop: "place-brico"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Mattapan", stop: "place-valrd"},
                %{route: "Mattapan", stop: "place-capst"}
              ]
            },
            %Alert{
              effect: :suspension,
              informed_entities: [
                %{route: "Red", stop: "place-portr"}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :contracted,
            alerts: [
              %{
                location: "mbta.com/alerts",
                route_pill: %{branches: [:m], color: :red, text: "RL", type: :text},
                status: "2 current alerts"
              }
            ]
          },
          green: %{
            alerts: [
              %{
                route_pill: %{color: :green, text: "GL", type: :text},
                status: "Stop Skipped",
                location: %{full: "Lechmere", abbrev: "Lechmere"},
                station_count: 1
              },
              %{
                status: "Stop Skipped",
                location: %{full: "Packards Corner", abbrev: "Packards Cn"},
                route_pill: %{type: :text, text: "GL", color: :green, branches: [:b]},
                station_count: 1
              }
            ],
            type: :contracted
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
              all_platforms_at_informed_stations: [
                %{id: "70065", platform_name: "Ashmont/Braintree"},
                %{id: "70066", platform_name: "Alewife"}
              ]
            }
          }
        ]
      }

      expected = %{
        @normal_service
        | red: %{
            type: :extended,
            alert: %{
              status: "Stop Skipped",
              location: %{
                full: "Porter: Ashmont/Braintree platform closed",
                abbrev: "Porter (1 side only)"
              },
              route_pill: @rl_pill
            }
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 platform closure alert on Green Line" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-D", stop: "place-eliot", route_type: 1},
                %{route: "Green-D", stop: "70166", route_type: 1}
              ]
            },
            context: %{
              all_platforms_at_informed_stations: [
                %{id: "70166", platform_name: "Park Street & North"},
                %{id: "70167", platform_name: "Riverside"}
              ]
            }
          }
        ]
      }

      expected = %{
        @normal_service
        | green: %{
            type: :extended,
            alert: %{
              status: "Stop Skipped",
              location: %{
                full: "Eliot: Park Street & North platform closed",
                abbrev: "Eliot (1 side only)"
              },
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:d]}
            }
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles GL partial station closure for multiple branches" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Green-B", stop: "place-gover"},
                %{route: "Green-C", stop: "place-gover"},
                %{route: "Green-D", stop: "place-gover"},
                %{route: "Green-E", stop: "place-gover"},
                %{route: "Green-B", stop: "70201"},
                %{route: "Green-C", stop: "70201"},
                %{route: "Green-D", stop: "70201"},
                %{route: "Green-E", stop: "70201"}
              ]
            },
            context: %{
              all_platforms_at_informed_stations: [
                %{id: "70201", platform_name: "North Station & North"},
                %{id: "70202", platform_name: "Copley & West"}
              ]
            }
          }
        ]
      }

      expected = %{
        @normal_service
        | green: %{
            type: :extended,
            alert: %{
              route_pill: @gl_pill,
              status: "Stop Skipped",
              location: %{abbrev: "mbta.com/alerts", full: "mbta.com/alerts"},
              station_count: 1
            }
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles single platform closure alert at multiple stops" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              effect: :station_closure,
              informed_entities: [
                %{route: "Red", stop: "place-portr", route_type: 1},
                %{route: "Red", stop: "70065", route_type: 1},
                %{route: "Red", stop: "place-davis", route_type: 1},
                %{route: "Red", stop: "70063", route_type: 1}
              ]
            },
            context: %{
              all_platforms_at_informed_stations: [
                %{id: "70063", platform_name: "Ashmont/Braintree"},
                %{id: "70064", platform_name: "Alewife"},
                %{id: "70065", platform_name: "Ashmont/Braintree"},
                %{id: "70066", platform_name: "Alewife"}
              ]
            }
          }
        ]
      }

      expected = %{
        @normal_service
        | red: %{
            type: :extended,
            alert: %{
              status: "2 Stops Skipped",
              location: %{
                full: "mbta.com/alerts",
                abbrev: "mbta.com/alerts"
              },
              route_pill: @rl_pill,
              station_count: 2
            }
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 service change alert" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              effect: :service_change,
              informed_entities: [
                %{route: "Red", stop: "place-portr", route_type: 1},
                %{route: "Red", stop: "70065", route_type: 1}
              ]
            },
            context: %{
              all_platforms_at_informed_stations: [
                %{id: "70065", platform_name: "Ashmont/Braintree"},
                %{id: "70066", platform_name: "Alewife"}
              ]
            }
          }
        ]
      }

      expected = %{
        @normal_service
        | red: %{
            type: :extended,
            alert: %{
              status: "Service Change",
              location: %{full: "Porter", abbrev: "Porter"},
              route_pill: @rl_pill
            }
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles an informational single-tracking alert" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              cause: :single_tracking,
              effect: :delay,
              severity: 1,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"},
                %{route: "Orange", stop: "place-mlmnl"},
                %{route: "Orange", stop: "place-welln"}
              ]
            }
          }
        ]
      }

      expected = %{
        @normal_service
        | orange: %{
            type: :extended,
            alert: %{
              status: "Single Tracking",
              location: %{full: "Oak Grove ↔ Wellington", abbrev: "Oak Grove ↔ Wellington"},
              route_pill: @ol_pill
            }
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles a non-informational single-tracking alert" do
      instance = %SubwayStatus{
        subway_alerts: [
          %{
            alert: %Alert{
              cause: :single_tracking,
              effect: :delay,
              severity: 4,
              informed_entities: [
                %{route: "Orange", stop: "place-ogmnl"},
                %{route: "Orange", stop: "place-mlmnl"},
                %{route: "Orange", stop: "place-welln"}
              ]
            }
          }
        ]
      }

      expected = %{
        @normal_service
        | orange: %{
            type: :extended,
            alert: %{
              status: "Delays up to 15 minutes",
              location: %{full: "Due to Single Tracking", abbrev: "Single Tracking"},
              route_pill: @ol_pill
            }
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
              all_platforms_at_informed_stations: [
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
        @normal_service
        | red: %{
            type: :extended,
            alert: %{
              status: "Stop Skipped",
              location: %{full: "mbta.com/alerts", abbrev: "mbta.com/alerts"},
              route_pill: @rl_pill
            }
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
        @normal_service
        | blue: %{
            type: :extended,
            alert: %{route_pill: @bl_pill, status: "Shuttle Bus", location: "Entire line"}
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
        @normal_service
        | blue: %{
            type: :extended,
            alert: %{route_pill: @bl_pill, status: "SERVICE SUSPENDED", location: "Entire line"}
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
        @normal_service
        | green: %{
            type: :extended,
            alert: %{route_pill: @gl_pill, status: "SERVICE SUSPENDED", location: "Entire line"}
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
        @normal_service
        | blue: %{
            type: :extended,
            alert: %{route_pill: @bl_pill, status: "Delays over 60 minutes", location: nil}
          }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "uses 'Entire Mattapan line' location text for whole-line shuttles on Mattapan" do
      instance = %SubwayStatus{
        subway_alerts:
          subway_alerts([
            %Alert{
              effect: :shuttle,
              informed_entities: [
                %{route: "Mattapan", route_type: 1, direction_id: nil, stop: nil}
              ]
            }
          ])
      }

      expected = %{
        @normal_service
        | red: %{
            type: :extended,
            alert: %{
              route_pill: @rl_pill_mattapan,
              status: "Shuttle Bus",
              location: "Entire Mattapan line"
            }
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
        @normal_service
        | green: %{
            type: :extended,
            alert: %{
              location: %{abbrev: "Kenmore ↔ Kent St", full: "Kenmore ↔ Kent Street"},
              route_pill: gl_pill([:c]),
              status: "Shuttle Bus"
            }
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
    test "returns [3]" do
      instance = %SubwayStatus{}
      assert [3] == WidgetInstance.audio_sort_key(instance)
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

# test cases to add
# 1 mattapan alert, no rl alert
# 1 rl alert no mattapan alert
# 1 rl alert 1 mattapan alert
# 2 gl alerts and 2 rl alerts w/ branches
