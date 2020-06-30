# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :screens, ScreensWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0XmZH5iePmWrvV+PgrsU5z6WFgYupY2Zoh7FEk8pzuDLWftBrF/KtLBbG615wstt",
  render_errors: [view: ScreensWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Screens.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Use the HTML encoder for SSML files as well
config :phoenix, :format_encoders,
  html: Phoenix.Template.HTML,
  ssml: Phoenix.Template.HTML

# Use Jason for JSON parsing in ExAws
config :ex_aws, json_codec: Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :screens, :redirect_http?, true

config :screens,
  gds_dms_username: "mbtadata@gmail.com",
  override_fetcher: Screens.Override.Fetch,
  screen_data: %{
    "1" => %{stop_id: "1722", app_id: "bus_eink", name: "100301 1624 Blue B001"},
    "2" => %{stop_id: "383", app_id: "bus_eink", name: "100303 Blue Hill Ave B002"},
    "3" => %{stop_id: "5496", app_id: "bus_eink", name: "100311 Broadway Nor B003"},
    "4" => %{stop_id: "2134", app_id: "bus_eink", name: "100105 Church Lex B004"},
    "5" => %{stop_id: "32549", app_id: "bus_eink", name: "100313 Eliot Bennett B005"},
    "6" => %{stop_id: "22549", app_id: "bus_eink", name: "100315 Harvard Sq B006"},
    "7" => %{stop_id: "5615", app_id: "bus_eink", name: "100319 Hawthorne B007"},
    "8" => %{stop_id: "36466", app_id: "bus_eink", name: "100302 Hyde Park Oak B008"},
    "9" => %{stop_id: "11257", app_id: "bus_eink", name: "100317 Malcolm X B009"},
    "10" => %{stop_id: "58", app_id: "bus_eink", name: "100316 Mass Ave Harr B010"},
    "11" => %{stop_id: "21365", app_id: "bus_eink", name: "100304 Huntington B011"},
    "12" => %{stop_id: "178", app_id: "bus_eink", name: "100322 St James Dart B012"},
    "13" => %{stop_id: "6564", app_id: "bus_eink"},
    "14" => %{stop_id: "1357", app_id: "bus_eink", name: "100323 Tremont opp Rox B014"},
    "15" => %{stop_id: "390", app_id: "bus_eink", name: "100305 Warren Quincy B015"},
    "16" => %{stop_id: "407", app_id: "bus_eink", name: "100306 Warren Towns B016"},
    "17" => %{stop_id: "5605", app_id: "bus_eink", name: "100309 Wash Broad B017"},
    "18" => %{stop_id: "637", app_id: "bus_eink", name: "100308 Wash Firth B018"},
    "19" => %{stop_id: "8178", app_id: "bus_eink", name: "100310 Watertown Sq B019"},
    "101" => %{
      stop_id: "place-bland",
      platform_id: "70148",
      route_id: "Green-B",
      direction_id: 1,
      app_id: "gl_eink_single",
      name: "002047 Blandford EB GL01"
    },
    "111" => %{
      stop_id: "place-bland",
      platform_id: "70148",
      route_id: "Green-B",
      direction_id: 1,
      app_id: "gl_eink_single",
      name: "002046 Blandford EB GL02"
    },
    "102" => %{
      stop_id: "place-bland",
      platform_id: "70149",
      route_id: "Green-B",
      direction_id: 0,
      app_id: "gl_eink_single",
      name: "002051 Blandford WB GL04"
    },
    "112" => %{
      stop_id: "place-bland",
      platform_id: "70149",
      route_id: "Green-B",
      direction_id: 0,
      app_id: "gl_eink_single",
      name: "002049 Blandford WB GL03"
    },
    "103" => %{
      stop_id: "place-bcnwa",
      platform_id: "70230",
      route_id: "Green-C",
      direction_id: 1,
      app_id: "gl_eink_single"
    },
    "104" => %{
      stop_id: "place-bcnwa",
      platform_id: "70229",
      route_id: "Green-C",
      direction_id: 0,
      app_id: "gl_eink_single",
      name: "002050 Wash Sq WB GL07"
    },
    "105" => %{
      stop_id: "place-mfa",
      platform_id: "70246",
      route_id: "Green-E",
      direction_id: 1,
      app_id: "gl_eink_single"
    },
    "106" => %{
      stop_id: "place-mfa",
      platform_id: "70245",
      route_id: "Green-E",
      direction_id: 0,
      app_id: "gl_eink_single"
    },
    "201" => %{
      stop_id: "place-bland",
      platform_id: "70148",
      route_id: "Green-B",
      direction_id: 1,
      app_id: "gl_eink_double"
    },
    "202" => %{
      stop_id: "place-bland",
      platform_id: "70149",
      route_id: "Green-B",
      direction_id: 0,
      app_id: "gl_eink_double"
    },
    "203" => %{
      stop_id: "place-bcnwa",
      platform_id: "70230",
      route_id: "Green-C",
      direction_id: 1,
      app_id: "gl_eink_double",
      name: "100098 Wash Sq EB GL05"
    },
    "213" => %{
      stop_id: "place-bcnwa",
      platform_id: "70230",
      route_id: "Green-C",
      direction_id: 1,
      app_id: "gl_eink_double",
      name: "100102 Wash Sq EB GL06"
    },
    "204" => %{
      stop_id: "place-bcnwa",
      platform_id: "70229",
      route_id: "Green-C",
      direction_id: 0,
      app_id: "gl_eink_double",
      name: "100097 Wash Sq WB GL08"
    },
    "205" => %{
      stop_id: "place-mfa",
      platform_id: "70246",
      route_id: "Green-E",
      direction_id: 1,
      app_id: "gl_eink_double"
    },
    "206" => %{
      stop_id: "place-mfa",
      platform_id: "70245",
      route_id: "Green-E",
      direction_id: 0,
      app_id: "gl_eink_double",
      name: "002013 MFA WB GL10"
    },
    "216" => %{
      stop_id: "place-mfa",
      platform_id: "70245",
      route_id: "Green-E",
      direction_id: 0,
      app_id: "gl_eink_double",
      name: "100101 MFA WB GL09"
    },
    "301" => %{
      station_name: "Ashmont",
      overhead: false,
      section_headers: nil,
      sections: [
        %{
          name: "Red Line",
          arrow: :e,
          query: %{params: %{stop_id: "70094"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 2}},
          audio: %{wayfinding: nil},
          pill: :red
        },
        %{
          name: "Mattapan Trolley",
          arrow: :e,
          query: %{params: %{stop_id: "70261"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 1}},
          audio: %{wayfinding: nil},
          pill: :mattapan
        },
        %{
          name: "Busway",
          arrow: :s,
          query: %{params: %{stop_id: "334"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 14, visible_rows: 10, paged: true}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Ashmont SOL01"
    },
    "302" => %{
      station_name: "Central",
      overhead: false,
      section_headers: nil,
      sections: [
        %{
          name: "Red Line",
          arrow: nil,
          query: %{params: %{stop_ids: ["70069", "70070"]}, opts: %{}},
          layout: :bidirectional,
          audio: %{wayfinding: nil},
          pill: :red
        },
        %{
          name: "Bus",
          arrow: nil,
          query: %{params: %{stop_ids: ["72", "102", "1060", "1123"]}, opts: %{}},
          layout:
            {:upcoming,
             %{
               num_rows: 14,
               visible_rows: 10,
               paged: true,
               routes: {:exclude, [{"70", 1}, {"64", 1}]}
             }},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Central SOL02"
    },
    "303" => %{
      station_name: "Nubian",
      overhead: true,
      section_headers: :normal,
      sections: [
        %{
          name: "Platform A",
          arrow: nil,
          query: %{
            params: %{
              stop_id: "place-dudly",
              route_ids: ["15", "23", "28", "44", "45"],
              direction_id: 1
            },
            opts: %{}
          },
          layout: {:upcoming, %{num_rows: 8}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Nubian Platform A SOL03"
    },
    "304" => %{
      station_name: "Nubian",
      overhead: true,
      section_headers: :normal,
      sections: [
        %{
          name: "Platform C",
          arrow: nil,
          query: %{
            params: %{stop_id: "place-dudly"},
            opts: %{}
          },
          layout:
            {:upcoming,
             %{
               num_rows: 8,
               routes: {:include, [{"14", 1}, {"41", 0}, {"42", 0}, {"66", 0}]}
             }},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Nubian Platform C SOL"
    },
    "305" => %{
      station_name: "Forest Hills",
      overhead: false,
      section_headers: :vertical,
      sections: [
        %{
          name: "Upper Busway",
          arrow: :e,
          query: %{params: %{stop_id: "10642"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 10, visible_rows: 6, paged: true}},
          audio: %{wayfinding: "Upper Busway"},
          pill: :bus
        },
        %{
          name: "Lower Busway",
          arrow: :n,
          query: %{params: %{stop_id: "875"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 10, visible_rows: 6, paged: true}},
          audio: %{wayfinding: "Upper Busway"},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Forest Hills Lobby SOL05"
    },
    "306" => %{
      station_name: "Forest Hills",
      overhead: false,
      section_headers: nil,
      sections: [
        %{
          name: "Commuter Rail",
          arrow: :w,
          query: %{params: %{stop_id: "Forest Hills"}, opts: %{include_schedules: true}},
          layout: :bidirectional,
          audio: %{wayfinding: nil},
          pill: :cr
        },
        %{
          name: "Upper Busway",
          arrow: :e,
          query: %{params: %{stop_id: "10642"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 14, visible_rows: 10, paged: true}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Forest Hills Upper Busway SOL06"
    },
    "307" => %{
      station_name: "Harvard",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Upper Busway",
          arrow: :e,
          query: %{params: %{stop_id: "20762"}, opts: %{}},
          layout:
            {:upcoming,
             %{
               num_rows: 14,
               visible_rows: 10,
               paged: true,
               routes: {:exclude, [{"74", 1}, {"75", 1}, {"77", 1}, {"78", 1}, {"96", 1}]}
             }},
          audio: %{wayfinding: "Upper Busway"},
          pill: :bus
        },
        %{
          name: "Lower Busway",
          arrow: :e,
          query: %{params: %{stop_id: "2076"}, opts: %{}},
          layout:
            {:upcoming,
             %{
               num_rows: 2,
               routes: {:exclude, [{"74", 1}, {"75", 1}, {"77", 1}, {"78", 1}, {"96", 1}]}
             }},
          audio: %{wayfinding: "Lower Busway"},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Harvard SOL07"
    },
    "308" => %{
      station_name: "Haymarket",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Busway",
          arrow: :se,
          query: %{params: %{stop_id: "8310"}, opts: %{}},
          layout:
            {:upcoming,
             %{
               num_rows: 12,
               visible_rows: 8,
               paged: true,
               routes: {:exclude, [{"92", 1}, {"93", 1}]}
             }},
          audio: %{wayfinding: "Busway"},
          pill: :bus
        },
        %{
          name: "Congress St @ Haymarket Sta",
          arrow: :n,
          query: %{params: %{stop_id: "117"}, opts: %{}},
          layout:
            {:upcoming,
             %{num_rows: 8, visible_rows: 4, paged: true, routes: {:exclude, [{"4", 0}]}}},
          audio: %{wayfinding: "Congress Street at Haymarket Station"},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Haymarket SOL08"
    },
    "309" => %{
      station_name: "Maverick",
      overhead: false,
      section_headers: nil,
      sections: [
        %{
          name: "Blue Line",
          arrow: :e,
          query: %{params: %{stop_ids: ["70045", "70046"]}, opts: %{}},
          layout: :bidirectional,
          audio: %{wayfinding: nil},
          pill: :blue
        },
        %{
          name: "Bus",
          arrow: :w,
          query: %{params: %{stop_ids: ["5740", "57400"]}, opts: %{}},
          layout: {:upcoming, %{num_rows: 14, visible_rows: 10, paged: true}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Maverick SOL09"
    },
    "310" => %{
      station_name: "Ruggles",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Lower Busway",
          arrow: :e,
          query: %{params: %{stop_ids: ["17862", "17863"]}, opts: %{}},
          layout: {:upcoming, %{num_rows: 14, visible_rows: 10, paged: true}},
          audio: %{wayfinding: "Lower Busway"},
          pill: :bus
        },
        %{
          name: "Commuter Rail",
          arrow: :e,
          query: %{params: %{stop_id: "Ruggles"}, opts: %{include_schedules: true}},
          layout: {:upcoming, %{num_rows: 2}},
          audio: %{wayfinding: nil},
          pill: :cr
        }
      ],
      app_id: "solari",
      name: "Ruggles SOL10"
    },
    "311" => %{
      station_name: "Sullivan Square",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Upper Busway",
          arrow: :w,
          query: %{
            params: %{stop_ids: ["29001", "29002", "29003", "29004", "29005", "29006"]},
            opts: %{}
          },
          layout:
            {:upcoming, %{num_rows: 10, visible_rows: 6, paged: true, routes: {:exclude, ["90"]}}},
          audio: %{wayfinding: "Upper Busway"},
          pill: :bus
        },
        %{
          name: "Lower Busway",
          arrow: :sw,
          query: %{
            params: %{
              stop_ids: ["29007", "29008", "29009", "29010", "29011", "29012", "29013", "29014"]
            },
            opts: %{}
          },
          layout: {:upcoming, %{num_rows: 12, visible_rows: 8, paged: true}},
          audio: %{wayfinding: "Lower Busway"},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Sullivan Square SOL11"
    },
    "312" => %{
      station_name: "Wonderland",
      overhead: false,
      section_headers: nil,
      sections: [
        %{
          name: "Blue Line",
          arrow: :se,
          query: %{params: %{stop_id: "70059"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 2}},
          audio: %{wayfinding: nil},
          pill: :blue
        },
        %{
          name: "Bus",
          arrow: :w,
          query: %{params: %{stop_id: "15795"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 14, visible_rows: 10, paged: true}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "Wonderland SOL12"
    },
    "313" => %{
      station_name: "10 Park Plaza",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Commuter Rail (South Station)",
          arrow: :w,
          query: %{params: %{stop_id: "South Station"}, opts: %{include_schedules: true}},
          layout: {:upcoming, %{num_rows: 7, visible_rows: 3, paged: true, max_minutes: 120}},
          audio: %{wayfinding: "South Station"},
          pill: :cr
        },
        %{
          name: "Tufts Medical Center",
          arrow: :nw,
          query: %{params: %{stop_ids: ["70016", "70017"]}, opts: %{}},
          layout: :bidirectional,
          audio: %{wayfinding: "Tufts Medical Center"},
          pill: :orange
        },
        %{
          name: nil,
          arrow: nil,
          query: %{params: %{stop_ids: ["49002", "6565"]}, opts: %{}},
          layout: {:bidirectional, %{routes: {:exclude, ["11"]}}},
          audio: %{wayfinding: "Tufts Medical Center"},
          pill: :silver
        },
        %{
          name: "Bus",
          arrow: :e,
          query: %{params: %{stop_id: "9983"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 1}},
          audio: %{wayfinding: "Stuart Street at Charles Street South"},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "10 Park Plaza Stuart SOL13"
    },
    "314" => %{
      station_name: "10 Park Plaza",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Commuter Rail (Back Bay)",
          arrow: :nw,
          query: %{
            params: %{stop_id: "Back Bay", direction_id: 0},
            opts: %{include_schedules: true}
          },
          layout: {:upcoming, %{num_rows: 8, max_minutes: 120}},
          audio: %{wayfinding: "Back Bay"},
          pill: :cr
        },
        %{
          name: "Bus",
          arrow: nil,
          query: %{params: %{stop_ids: ["145", "1241", "9983"]}, opts: %{}},
          layout: {:upcoming, %{num_rows: 2}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari",
      name: "10 Park Plaza Charles SOL14"
    },
    "320" => %{
      station_name: "Summer Street",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Summer St opp WTC Ave",
          arrow: nil,
          query: %{params: %{stop_id: "889"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 8}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari"
    },
    "321" => %{
      station_name: "Summer Street",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Summer St @ WTC Ave",
          arrow: nil,
          query: %{params: %{stop_id: "890"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 8}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari"
    },
    "322" => %{
      station_name: "Columbus Ave",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Columbus Ave @ Walnut Ave",
          arrow: nil,
          query: %{params: %{stop_id: "1743"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 8}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari"
    },
    "323" => %{
      station_name: "Columbus Ave",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Columbus Ave @ Walnut Ave",
          arrow: nil,
          query: %{params: %{stop_id: "11413"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 8}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari"
    },
    "324" => %{
      station_name: "Columbus Ave",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Seaver St opp Elm Hill Ave",
          arrow: nil,
          query: %{params: %{stop_id: "17401"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 8}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari"
    },
    "325" => %{
      station_name: "Blue Hill Ave",
      overhead: false,
      section_headers: :normal,
      sections: [
        %{
          name: "Blue Hill Ave @ Ellington St",
          arrow: nil,
          query: %{params: %{stop_id: "383"}, opts: %{}},
          layout: {:upcoming, %{num_rows: 8}},
          audio: %{wayfinding: nil},
          pill: :bus
        }
      ],
      app_id: "solari"
    }
  },
  api_v3_url: "https://api-v3.mbta.com/",
  nearby_departures: %{
    "place-bland" => ["941", "951"],
    "place-bcnwa" => ["1276", "1292"],
    "place-mfa" => ["51317", "71391"],
    "place-newto" => ["8504", "8528"]
  },
  nearby_connections: %{
    "1722" => ["place-matt", "place-DB-2222"],
    "383" => ["2923", "568"],
    "5496" => ["5403"],
    "2134" => ["place-FR-0074", "2137"],
    "32549" => ["place-harsq", "110"],
    "22549" => ["2168", "place-harsq"],
    "5615" => ["place-belsq", "place-ER-0046"],
    "36466" => ["26531", "place-NEC-2203"],
    "11257" => ["1144", "place-rcmnl"],
    "58" => ["1790", "5"],
    "21365" => ["place-rvrwy", "1314"],
    "178" => ["place-coecl", "175"],
    "6564" => ["place-sstat", "6538"],
    "1357" => ["place-rcmnl"],
    "390" => ["1332", "1569"],
    "407" => ["1346", "1583"],
    "5605" => ["place-belsq", "place-ER-0046"],
    "637" => ["6428", "place-NB-0064"],
    "8178" => ["900", "8297"],
    # Empty placeholders until we decide what to do about nearby connections/departures
    "place-bland" => [],
    "place-bcnwa" => [],
    "place-mfa" => [],
    "place-newto" => []
  },
  routes_at_stop: %{
    "110" => ["1", "68", "69"],
    "11257" => ["15", "23", "28", "44", "45", "66"],
    "1144" => ["14", "41"],
    "1314" => ["66"],
    "1332" => ["44"],
    "1346" => ["44"],
    "1357" => ["66"],
    "1569" => ["45"],
    "1583" => ["45"],
    "1722" => ["28", "29", "31"],
    "175" => ["9", "39", "55"],
    "178" => ["9", "10", "39", "502", "503", "504", "55"],
    "1790" => ["8", "47", "CT3"],
    "2134" => ["73"],
    "21365" => ["39"],
    "2137" => ["74", "75"],
    "2168" => ["1", "66", "68", "69"],
    "22549" => ["66", "86"],
    "26531" => ["33", "40/50", "50"],
    "2923" => ["16"],
    "32549" => ["66", "74", "75", "77", "78", "86", "96"],
    "36466" => ["32", "40/50", "50"],
    "383" => ["14", "22", "28", "29", "45"],
    "390" => ["14", "19", "23", "28"],
    "407" => ["14", "19", "23", "28"],
    "5" => ["SL4", "SL5", "8"],
    "5403" => ["99", "105", "106"],
    "5496" => ["104", "109", "110", "112", "97"],
    "5605" => ["111", "112", "114", "116", "116/117", "117"],
    "5615" => ["111", "112", "114", "116", "116/117", "117"],
    "568" => ["19"],
    "58" => ["1"],
    "637" => ["30", "34", "34E", "35", "36", "37", "40", "40/50", "50", "51"],
    "6428" => ["14", "30"],
    "6538" => ["SL4"],
    "6564" => ["4", "7", "11"],
    "8178" => ["59", "71"],
    "8297" => ["70"],
    "900" => ["52", "57", "502", "504"],
    "place-DB-2222" => ["CR-Fairmount"],
    "place-ER-0046" => ["CR-Newburyport"],
    "place-FR-0074" => ["CR-Fitchburg"],
    "place-NB-0064" => ["CR-Needham"],
    "place-NEC-2203" => ["CR-Franklin", "CR-Providence"],
    "place-belsq" => ["SL3"],
    "place-coecl" => ["Green Line"],
    # "place-harsq" => ["Red Line", "71", "72", "73", "74", "75", "77", "78", "86", "96"],
    "place-harsq" => ["Red Line", "Bus"],
    # "place-matt" => ["Mattapan", "24", "24/27", "245", "27", "28", "29", "30", "31", "33", "716"],
    "place-matt" => ["Mattapan", "Bus"],
    "place-rcmnl" => ["Orange Line"],
    "place-rvrwy" => ["Green Line • E"],
    "place-sstat" => ["Red Line", "SL 1", "SL2", "SL3", "Commuter Rail"]
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
