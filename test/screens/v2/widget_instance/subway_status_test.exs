defmodule Screens.V2.WidgetInstance.SubwayStatusTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{BusShelter, Departures, PreFare}
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.SubwayStatus

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
        subway_alerts: [
          %Alert{
            effect: :station_closure,
            informed_entities: [
              %{route: "Blue", stop: "place-aport"},
              %{route: "Blue", stop: "place-mvbcl"},
              %{route: "Blue", stop: "place-aqucl"},
              %{route: "Blue", stop: "place-state"}
            ]
          }
        ]
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
            }
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
        subway_alerts: [
          %Alert{
            effect: :station_closure,
            informed_entities: [
              %{route: "Blue", stop: "place-aport"},
              %{route: "Blue", stop: "place-mvbcl"},
              %{route: "Blue", stop: "place-aqucl"}
            ]
          }
        ]
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
            }
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
        subway_alerts: [
          %Alert{
            effect: :station_closure,
            informed_entities: [
              %{route: "Blue", stop: "place-aport"},
              %{route: "Blue", stop: "place-mvbcl"}
            ]
          }
        ]
      }

      expected = %{
        blue: %{
          type: :extended,
          alert: %{
            route_pill: %{type: :text, text: "BL", color: :blue},
            status: "Bypassing",
            location: %{abbrev: "Airport and Maverick", full: "Airport and Maverick"}
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
        subway_alerts: [
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
        ]
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
        subway_alerts: [
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
        ]
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
        subway_alerts: [
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
        ]
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
        subway_alerts: [
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
        ]
      }

      expected = %{
        blue: %{
          type: :contracted,
          alerts: [
            %{
              route_pill: %{type: :text, text: "BL", color: :blue},
              status: "Bypassing",
              location: %{abbrev: "Airport", full: "Airport"}
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

    test "handles 1 alert on GL trunk and 1 alert on GL branch" do
      instance = %SubwayStatus{
        subway_alerts: [
          %Alert{
            effect: :suspension,
            informed_entities: [
              %{route: "Green-C", stop: "place-gover"},
              %{route: "Green-C", stop: "place-pktrm"},
              %{route: "Green-C", stop: "place-boyls"}
            ]
          },
          %Alert{
            effect: :station_closure,
            informed_entities: [
              %{route: "Green-D", stop: "place-woodl"},
              %{route: "Green-D", stop: "place-river"}
            ]
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
              status: "Suspension",
              location: %{abbrev: "Gov't Ctr to Boylston", full: "Government Center to Boylston"}
            },
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:d]},
              status: "Bypassing",
              location: %{abbrev: "Woodland and Riverside", full: "Woodland and Riverside"}
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 1 alert on GL trunk and 2 alerts on GL branch" do
      instance = %SubwayStatus{
        subway_alerts: [
          %Alert{
            effect: :suspension,
            informed_entities: [
              %{route: "Green-C", stop: "place-gover"},
              %{route: "Green-C", stop: "place-pktrm"},
              %{route: "Green-C", stop: "place-boyls"}
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
              status: "Suspension",
              location: %{abbrev: "Gov't Ctr to Boylston", full: "Government Center to Boylston"}
            },
            %{
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:b, :e]},
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
        subway_alerts: [
          %Alert{
            effect: :suspension,
            informed_entities: [
              %{route: "Green-C", stop: "place-gover"},
              %{route: "Green-C", stop: "place-pktrm"},
              %{route: "Green-C", stop: "place-boyls"}
            ]
          },
          %Alert{
            effect: :delay,
            severity: 5,
            informed_entities: [
              %{route: "Green-E", stop: "place-lech"},
              %{route: "Green-E", stop: "place-spmnl"},
              %{route: "Green-E", stop: "place-north"}
            ]
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
              location: %{abbrev: "Gov't Ctr to Boylston", full: "Government Center to Boylston"},
              route_pill: %{color: :green, text: "GL", type: :text},
              status: "Suspension"
            },
            %{
              location: %{abbrev: "Lechmere to North Sta", full: "Lechmere to North Station"},
              route_pill: %{color: :green, text: "GL", type: :text},
              status: "Delays up to 20 minutes"
            }
          ]
        }
      }

      assert expected == WidgetInstance.serialize(instance)
    end

    test "handles 2 alerts on GL branches" do
      instance = %SubwayStatus{
        subway_alerts: [
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
        subway_alerts: [
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
        subway_alerts: [
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
              status: "Bypassing",
              location: %{abbrev: "Oak Grove", full: "Oak Grove"}
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
        subway_alerts: [
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
              %{route: "Green-D", stop: "place-gover"},
              %{route: "Green-D", stop: "place-pktrm"},
              %{route: "Green-D", stop: "place-boyls"}
            ]
          },
          %Alert{
            effect: :station_closure,
            informed_entities: [
              %{route: "Green-D", stop: "place-unsqu"}
            ]
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
        subway_alerts: [
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

    test "handles 2 alerts on GL branches and 2 alerts on non-GL route on e-Ink" do
      instance = %SubwayStatus{
        screen: struct(Screen, app_id: :bus_eink_v2),
        subway_alerts: [
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
              %{route: "Green-B", stop: nil, direction_id: 0}
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
              location: %{abbrev: "Oak Grove", full: "Oak Grove"},
              route_pill: %{color: :orange, text: "OL", type: :text},
              status: "Bypassing"
            },
            %{
              location: nil,
              route_pill: %{color: :orange, text: "OL", type: :text},
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
              route_pill: %{type: :text, text: "GL", color: :green, branches: [:b]},
              status: "Delays up to 20 minutes",
              location: %{abbrev: "Westbound", full: "Westbound"}
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

    test "uses 'Entire line' location text for whole-line shuttles" do
      instance = %SubwayStatus{
        subway_alerts: [
          %Alert{
            effect: :shuttle,
            informed_entities: [
              %{route: "Blue", route_type: 1, direction_id: nil, stop: nil}
            ]
          }
        ]
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
        subway_alerts: [
          %Alert{
            effect: :suspension,
            informed_entities: [
              %{route: "Blue", route_type: 1, direction_id: nil, stop: nil}
            ]
          }
        ]
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
        subway_alerts: [
          %Alert{
            effect: :suspension,
            informed_entities: [
              %{route: "Green-B", route_type: 0, direction_id: nil, stop: nil},
              %{route: "Green-C", route_type: 0, direction_id: nil, stop: nil},
              %{route: "Green-D", route_type: 0, direction_id: nil, stop: nil},
              %{route: "Green-E", route_type: 0, direction_id: nil, stop: nil}
            ]
          }
        ]
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
        subway_alerts: [
          %Alert{
            effect: :delay,
            severity: 9,
            informed_entities: [
              %{route: "Blue", route_type: 1, direction_id: nil, stop: nil}
            ]
          }
        ]
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
    test "returns [1]" do
      instance = %SubwayStatus{}
      assert [1] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true for PreFare" do
      instance = %SubwayStatus{
        screen: %Screen{
          app_params: struct(PreFare),
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        }
      }

      assert WidgetInstance.audio_valid_candidate?(instance)
    end

    test "returns false for BusShelter" do
      instance = %SubwayStatus{
        screen: %Screen{
          app_params: %BusShelter{
            departures: %Departures{
              sections: []
            },
            header: nil,
            footer: nil,
            alerts: nil
          },
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        }
      }

      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns SubwayStatusView" do
      instance = %SubwayStatus{}
      assert ScreensWeb.V2.Audio.SubwayStatusView == WidgetInstance.audio_view(instance)
    end
  end
end
