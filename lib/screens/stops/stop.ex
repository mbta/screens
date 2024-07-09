defmodule Screens.Stops.Stop do
  @moduledoc """
  This file handles involves stop-related fetching / enrichment.
  For a while, all stop-related data was fetched from the API, until we needed to provide consistent
  abbreviations in the reconstructed alert. Now it's valuable to have a local copy of these stop sequences.
  A lot of our code still collects these sequences from the API, though, whether in functions here
  or in functions in `route_pattern.ex` (see fetch_tagged_parent_station_sequences_through_stop).
  So there's inconsistent use of this local data.
  """

  require Logger

  alias Screens.LocationContext
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.{Routes, Stops}
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.StationsWithRoutesAgent
  alias Screens.Util
  alias Screens.V3Api
  alias ScreensConfig.V2.{BusEink, BusShelter, Dup, GlEink, PreFare, Triptych}

  defstruct id: nil,
            name: nil,
            platform_code: nil,
            platform_name: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          name: String.t(),
          platform_code: String.t() | nil,
          platform_name: String.t() | nil
        }

  @type screen_type :: BusEink | BusShelter | GlEink | PreFare | Dup | Triptych

  @blue_line_stops [
    {"place-wondl", {"Wonderland", "Wonderland"}},
    {"place-rbmnl", {"Revere Beach", "Revere Bch"}},
    {"place-bmmnl", {"Beachmont", "Beachmont"}},
    {"place-sdmnl", {"Suffolk Downs", "Suffolk Dns"}},
    {"place-orhte", {"Orient Heights", "Orient Hts"}},
    {"place-wimnl", {"Wood Island", "Wood Island"}},
    {"place-aport", {"Airport", "Airport"}},
    {"place-mvbcl", {"Maverick", "Maverick"}},
    {"place-aqucl", {"Aquarium", "Aquarium"}},
    {"place-state", {"State", "State"}},
    {"place-gover", {"Government Center", "Gov't Ctr"}},
    {"place-bomnl", {"Bowdoin", "Bowdoin"}}
  ]

  @orange_line_stops [
    {"place-ogmnl", {"Oak Grove", "Oak Grove"}},
    {"place-mlmnl", {"Malden Center", "Malden Ctr"}},
    {"place-welln", {"Wellington", "Wellington"}},
    {"place-astao", {"Assembly", "Assembly"}},
    {"place-sull", {"Sullivan Square", "Sullivan Sq"}},
    {"place-ccmnl", {"Community College", "Com College"}},
    {"place-north", {"North Station", "North Sta"}},
    {"place-haecl", {"Haymarket", "Haymarket"}},
    {"place-state", {"State", "State"}},
    {"place-dwnxg", {"Downtown Crossing", "Downt'n Xng"}},
    {"place-chncl", {"Chinatown", "Chinatown"}},
    {"place-tumnl", {"Tufts Medical Center", "Tufts Med"}},
    {"place-bbsta", {"Back Bay", "Back Bay"}},
    {"place-masta", {"Massachusetts Avenue", "Mass Ave"}},
    {"place-rugg", {"Ruggles", "Ruggles"}},
    {"place-rcmnl", {"Roxbury Crossing", "Roxbury Xng"}},
    {"place-jaksn", {"Jackson Square", "Jackson Sq"}},
    {"place-sbmnl", {"Stony Brook", "Stony Brook"}},
    {"place-grnst", {"Green Street", "Green St"}},
    {"place-forhl", {"Forest Hills", "Frst Hills"}}
  ]

  @red_line_trunk_stops [
    {"place-alfcl", {"Alewife", "Alewife"}},
    {"place-davis", {"Davis", "Davis"}},
    {"place-portr", {"Porter", "Porter"}},
    {"place-harsq", {"Harvard", "Harvard"}},
    {"place-cntsq", {"Central", "Central"}},
    {"place-knncl", {"Kendall/MIT", "Kendall/MIT"}},
    {"place-chmnl", {"Charles/MGH", "Charles/MGH"}},
    {"place-pktrm", {"Park Street", "Park St"}},
    {"place-dwnxg", {"Downtown Crossing", "Downt'n Xng"}},
    {"place-sstat", {"South Station", "South Sta"}},
    {"place-brdwy", {"Broadway", "Broadway"}},
    {"place-andrw", {"Andrew", "Andrew"}},
    {"place-jfk", {"JFK/UMass", "JFK/UMass"}}
  ]

  @red_line_ashmont_branch_stops [
    {"place-shmnl", {"Savin Hill", "Savin Hill"}},
    {"place-fldcr", {"Fields Corner", "Fields Cnr"}},
    {"place-smmnl", {"Shawmut", "Shawmut"}},
    {"place-asmnl", {"Ashmont", "Ashmont"}}
  ]

  @red_line_braintree_branch_stops [
    {"place-nqncy", {"North Quincy", "N Quincy"}},
    {"place-wlsta", {"Wollaston", "Wollaston"}},
    {"place-qnctr", {"Quincy Center", "Quincy Ctr"}},
    {"place-qamnl", {"Quincy Adams", "Quincy Adms"}},
    {"place-brntn", {"Braintree", "Braintree"}}
  ]

  @green_line_b_stops [
    {"place-gover", {"Government Center", "Gov't Ctr"}},
    {"place-pktrm", {"Park Street", "Park St"}},
    {"place-boyls", {"Boylston", "Boylston"}},
    {"place-armnl", {"Arlington", "Arlington"}},
    {"place-coecl", {"Copley", "Copley"}},
    {"place-hymnl", {"Hynes Convention Center", "Hynes"}},
    {"place-kencl", {"Kenmore", "Kenmore"}},
    {"place-bland", {"Blandford Street", "Blandford"}},
    {"place-buest", {"Boston University East", "BU East"}},
    {"place-bucen", {"Boston University Central", "BU Central"}},
    {"place-amory", {"Amory Street", "Amory St"}},
    {"place-babck", {"Babcock Street", "Babcock St"}},
    {"place-brico", {"Packards Corner", "Packards Cn"}},
    {"place-harvd", {"Harvard Avenue", "Harvard Ave"}},
    {"place-grigg", {"Griggs Street", "Griggs St"}},
    {"place-alsgr", {"Allston Street", "Allston St"}},
    {"place-wrnst", {"Warren Street", "Warren St"}},
    {"place-wascm", {"Washington Street", "Washington"}},
    {"place-sthld", {"Sutherland Road", "Sutherland"}},
    {"place-chswk", {"Chiswick Road", "Chiswick Rd"}},
    {"place-chill", {"Chestnut Hill Avenue", "Chestnut Hl"}},
    {"place-sougr", {"South Street", "South St"}},
    {"place-lake", {"Boston College", "Boston Coll"}}
  ]

  @green_line_c_stops [
    {"place-gover", {"Government Center", "Gov't Ctr"}},
    {"place-pktrm", {"Park Street", "Park St"}},
    {"place-boyls", {"Boylston", "Boylston"}},
    {"place-armnl", {"Arlington", "Arlington"}},
    {"place-coecl", {"Copley", "Copley"}},
    {"place-hymnl", {"Hynes Convention Center", "Hynes"}},
    {"place-kencl", {"Kenmore", "Kenmore"}},
    {"place-smary", {"Saint Mary's Street", "St. Mary's"}},
    {"place-hwsst", {"Hawes Street", "Hawes St"}},
    {"place-kntst", {"Kent Street", "Kent St"}},
    {"place-stpul", {"Saint Paul Street", "St. Paul St"}},
    {"place-cool", {"Coolidge Corner", "Coolidge Cn"}},
    {"place-sumav", {"Summit Avenue", "Summit Ave"}},
    {"place-bndhl", {"Brandon Hall", "Brandon Hll"}},
    {"place-fbkst", {"Fairbanks Street", "Fairbanks"}},
    {"place-bcnwa", {"Washington Square", "Washington"}},
    {"place-tapst", {"Tappan Street", "Tappan St"}},
    {"place-denrd", {"Dean Road", "Dean Rd"}},
    {"place-engav", {"Englewood Avenue", "Englew'd Av"}},
    {"place-clmnl", {"Cleveland Circle", "Clvlnd Cir"}}
  ]

  @green_line_d_stops [
    {"place-unsqu", {"Union Square", "Union Sq"}},
    {"place-lech", {"Lechmere", "Lechmere"}},
    {"place-spmnl", {"Science Park/West End", "Science Pk"}},
    {"place-north", {"North Station", "North Sta"}},
    {"place-haecl", {"Haymarket", "Haymarket"}},
    {"place-gover", {"Government Center", "Gov't Ctr"}},
    {"place-pktrm", {"Park Street", "Park St"}},
    {"place-boyls", {"Boylston", "Boylston"}},
    {"place-armnl", {"Arlington", "Arlington"}},
    {"place-coecl", {"Copley", "Copley"}},
    {"place-hymnl", {"Hynes Convention Center", "Hynes"}},
    {"place-kencl", {"Kenmore", "Kenmore"}},
    {"place-fenwy", {"Fenway", "Fenway"}},
    {"place-longw", {"Longwood", "Longwood"}},
    {"place-bvmnl", {"Brookline Village", "B'kline Vil"}},
    {"place-brkhl", {"Brookline Hills", "B'kline Hls"}},
    {"place-bcnfd", {"Beaconsfield", "B'consfield"}},
    {"place-rsmnl", {"Reservoir", "Reservoir"}},
    {"place-chhil", {"Chestnut Hill", "Chestnut Hl"}},
    {"place-newto", {"Newton Centre", "Newton Ctr"}},
    {"place-newtn", {"Newton Highlands", "Newton Hlnd"}},
    {"place-eliot", {"Eliot", "Eliot"}},
    {"place-waban", {"Waban", "Waban"}},
    {"place-woodl", {"Woodland", "Woodland"}},
    {"place-river", {"Riverside", "Riverside"}}
  ]

  @green_line_e_stops [
    {"place-mdftf", {"Medford / Tufts", "Medford"}},
    {"place-balsq", {"Ball Square", "Ball Sq"}},
    {"place-mgngl", {"Magoun Square", "Magoun Sq"}},
    {"place-gilmn", {"Gilman Square", "Gilman Sq"}},
    {"place-esomr", {"East Somerville", "E Somerville"}},
    {"place-lech", {"Lechmere", "Lechmere"}},
    {"place-spmnl", {"Science Park/West End", "Science Pk"}},
    {"place-north", {"North Station", "North Sta"}},
    {"place-haecl", {"Haymarket", "Haymarket"}},
    {"place-gover", {"Government Center", "Gov't Ctr"}},
    {"place-pktrm", {"Park Street", "Park St"}},
    {"place-boyls", {"Boylston", "Boylston"}},
    {"place-armnl", {"Arlington", "Arlington"}},
    {"place-coecl", {"Copley", "Copley"}},
    {"place-prmnl", {"Prudential", "Prudential"}},
    {"place-symcl", {"Symphony", "Symphony"}},
    {"place-nuniv", {"Northeastern University", "Northeast'n"}},
    {"place-mfa", {"Museum of Fine Arts", "MFA"}},
    {"place-lngmd", {"Longwood Medical Area", "Lngwd Med"}},
    {"place-brmnl", {"Brigham Circle", "Brigham Cir"}},
    {"place-fenwd", {"Fenwood Road", "Fenwood Rd"}},
    {"place-mispk", {"Mission Park", "Mission Pk"}},
    {"place-rvrwy", {"Riverway", "Riverway"}},
    {"place-bckhl", {"Back of the Hill", "Back o'Hill"}},
    {"place-hsmnl", {"Heath Street", "Heath St"}}
  ]

  @green_line_trunk_stops [
    {"place-lech", {"Lechmere", "Lechmere"}},
    {"place-spmnl", {"Science Park/West End", "Science Pk"}},
    {"place-north", {"North Station", "North Sta"}},
    {"place-haecl", {"Haymarket", "Haymarket"}},
    {"place-gover", {"Government Center", "Gov't Ctr"}},
    {"place-pktrm", {"Park Street", "Park St"}},
    {"place-boyls", {"Boylston", "Boylston"}},
    {"place-armnl", {"Arlington", "Arlington"}},
    {"place-coecl", {"Copley", "Copley"}},
    {"place-hymnl", {"Hynes Convention Center", "Hynes"}},
    {"place-kencl", {"Kenmore", "Kenmore"}}
  ]

  @medford_tufts_branch_stops [
    {"place-mdftf", {"Medford / Tufts", "Medford"}},
    {"place-balsq", {"Ball Square", "Ball Sq"}},
    {"place-mgngl", {"Magoun Square", "Magoun Sq"}},
    {"place-gilmn", {"Gilman Square", "Gilman Sq"}},
    {"place-esomr", {"East Somerville", "E Somerville"}}
  ]

  @union_square_branch_stops [
    {"place-unsqu", {"Union Square", "Union Sq"}}
  ]

  @route_stop_sequences %{
    "Blue" => [@blue_line_stops],
    "Orange" => [@orange_line_stops],
    "Red" => [
      @red_line_trunk_stops ++ @red_line_ashmont_branch_stops,
      @red_line_trunk_stops ++ @red_line_braintree_branch_stops
    ],
    "Green-B" => [@green_line_b_stops],
    "Green-C" => [@green_line_c_stops],
    "Green-D" => [@green_line_d_stops],
    "Green-E" => [@green_line_e_stops],
    "Green" => [@green_line_trunk_stops]
  }

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  # --- These functions involve the API ---

  def fetch_parent_station_name_map(get_json_fn \\ &V3Api.get_json/2) do
    case get_json_fn.("stops", %{
           "filter[location_type]" => 1
         }) do
      {:ok, %{"data" => data}} ->
        parsed =
          data
          |> Enum.map(fn %{"id" => id, "attributes" => %{"name" => name}} -> {id, name} end)
          |> Enum.into(%{})

        {:ok, parsed}

      _ ->
        :error
    end
  end

  def fetch_routes_serving_stop(
        station_id,
        get_json_fn \\ &V3Api.get_json/2,
        attempts_left \\ 3
      )

  def fetch_routes_serving_stop(_station_id, _get_json_fn, 0), do: :bad_response

  def fetch_routes_serving_stop(
        station_id,
        get_json_fn,
        attempts_left
      ) do
    case get_json_fn.("routes", %{"filter[stop]" => station_id}) do
      {:ok, %{"data" => []}, _} ->
        fetch_routes_serving_stop(station_id, get_json_fn, attempts_left - 1)

      {:ok, %{"data" => data}} ->
        {:ok, Enum.map(data, fn route -> Routes.Parser.parse_route(route) end)}

      _ ->
        :error
    end
  end

  # Returns a list of Route structs that serve the provided ID
  @spec create_station_with_routes_map(String.t()) :: list(Routes.Route.t())
  def create_station_with_routes_map(station_id) do
    case StationsWithRoutesAgent.get(station_id) do
      nil ->
        get_routes_serving_stop(station_id)

      routes ->
        get_routes_serving_stop(station_id, routes)
    end
  end

  defp get_routes_serving_stop(station_id, default_routes \\ []) do
    case fetch_routes_serving_stop(station_id) do
      {:ok, new_routes} ->
        new_routes

      :bad_response ->
        Logger.error(
          "[create_station_with_routes_map no routes] Received an empty list from API: stop_id=#{station_id}"
        )

        default_routes

      :error ->
        Logger.error(
          "[create_station_with_routes_map fetch error] Received an error from API: stop_id=#{station_id}"
        )

        default_routes
    end
  end

  def get_routes_serving_stop_ids(stop_ids) do
    stop_ids
    |> Enum.flat_map(fn stop_id ->
      stop_id
      |> create_station_with_routes_map()
      |> Enum.map(& &1.id)
    end)
    |> Enum.uniq()
  end

  def fetch_stop_name(stop_id) do
    Screens.Telemetry.span(~w[screens stops stop fetch_stop_name]a, %{stop_id: stop_id}, fn ->
      case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_id}) do
        {:ok, %{"data" => [stop_data]}} ->
          %{"attributes" => %{"name" => stop_name}} = stop_data
          stop_name

        _ ->
          nil
      end
    end)
  end

  def fetch_parent_stop_id(stop_id) do
    case Screens.V3Api.get_json("stops/" <> stop_id, %{"include" => "parent_station"}) do
      {:ok, %{"included" => [included_data]}} ->
        %{"id" => parent_station_id} = included_data
        parent_station_id

      _ ->
        nil
    end
  end

  def fetch_subway_platforms_for_stop(stop_id) do
    case Screens.V3Api.get_json("stops/" <> stop_id, %{"include" => "child_stops"}) do
      {:ok, %{"included" => child_stop_data}} ->
        child_stop_data
        |> Enum.filter(
          &match?(
            %{
              "attributes" => %{
                "location_type" => 0,
                "vehicle_type" => 1
              }
            },
            &1
          )
        )
        |> Enum.map(&Stops.Parser.parse_stop/1)
    end
  end

  # --- END API functions ---

  def stop_on_route?(stop_id, stop_sequence) when not is_nil(stop_id) do
    Enum.any?(stop_sequence, fn {station_id, _} -> station_id == stop_id end)
  end

  def to_stop_index(%{stop: stop_id}, stop_sequence) do
    Enum.find_index(stop_sequence, fn {station_id, _} -> station_id == stop_id end)
  end

  # --- These use the local version of the stop_sequences from the top of this file ---

  @doc """
  Finds a stop sequence which contains all stations in informed_entities.
  """
  def get_stop_sequence(informed_entities, "Green") do
    Enum.find_value(@green_line_branches, fn branch ->
      get_stop_sequence(informed_entities, branch)
    end)
  end

  def get_stop_sequence(informed_entities, route_id) do
    stop_sequences = Map.get(@route_stop_sequences, route_id)
    Enum.find(stop_sequences, &sequence_match?(&1, informed_entities))
  end

  def get_route_stop_sequence(route_id) do
    @route_stop_sequences
    |> Map.get(route_id)
    |> Enum.flat_map(fn x -> x end)
    |> Enum.map(fn {k, _v} -> k end)
    |> Enum.uniq()
  end

  def get_all_routes_stop_sequence do
    @route_stop_sequences
  end

  def get_gl_stop_sequences do
    Enum.map(@green_line_branches, &get_route_stop_sequence/1)
  end

  @doc """
  Returns an unordered MapSet of all GL stops west of Copley.
  """
  @spec get_gl_stops_west_of_copley() :: MapSet.t(id())
  def get_gl_stops_west_of_copley do
    get_gl_stop_sequences()
    |> Enum.flat_map(fn stop_sequence ->
      [_copley | west_of_copley] = Enum.drop_while(stop_sequence, &(&1 != "place-coecl"))
      west_of_copley
    end)
    |> MapSet.new()
  end

  defp sequence_match?(stop_sequence, informed_entities) do
    ie_stops =
      informed_entities
      |> Enum.map(fn %{stop: stop_id} -> stop_id end)
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(ie_stops) do
      nil
    else
      ie_stops
      |> Enum.filter(&String.starts_with?(&1, "place-"))
      |> Enum.all?(&stop_on_route?(&1, stop_sequence))
    end
  end

  def gl_trunk_stops do
    @green_line_trunk_stops
  end

  def rl_trunk_stops do
    @red_line_trunk_stops
  end

  def stop_id_to_name(route_id) do
    @route_stop_sequences
    |> Map.get(route_id)
    |> Enum.flat_map(fn x -> x end)
    |> Enum.uniq()
    |> Enum.into(%{})
  end

  @doc """
  Fetches all the location context for a screen given its app type, stop id, and time
  """
  @spec fetch_location_context(
          screen_type(),
          id(),
          DateTime.t()
        ) :: {:ok, LocationContext.t()} | :error
  def fetch_location_context(app, stop_id, now) do
    Screens.Telemetry.span(
      ~w[screens stops stop fetch_location_context]a,
      %{app: app, stop_id: stop_id},
      fn ->
        with alert_route_types <- get_route_type_filter(app, stop_id),
             {:ok, routes_at_stop} <- Route.fetch_routes_by_stop(stop_id, now, alert_route_types),
             {:ok, tagged_stop_sequences} <-
               fetch_tagged_stop_sequences_by_app(app, stop_id, routes_at_stop) do
          stop_name = fetch_stop_name(stop_id)
          stop_sequences = RoutePattern.untag_stop_sequences(tagged_stop_sequences)

          {:ok,
           %LocationContext{
             home_stop: stop_id,
             home_stop_name: stop_name,
             tagged_stop_sequences: tagged_stop_sequences,
             upstream_stops: upstream_stop_id_set(stop_id, stop_sequences),
             downstream_stops: downstream_stop_id_set(stop_id, stop_sequences),
             routes: routes_at_stop,
             alert_route_types: alert_route_types
           }}
        else
          :error ->
            Logger.error(
              "[fetch_location_context fetch error] Failed to get location context for an alert: stop_id=#{stop_id}"
            )

            :error
        end
      end
    )
  end

  # Returns the route types we care about for the alerts of this screen type / place
  @spec get_route_type_filter(screen_type(), String.t()) ::
          list(RouteType.t())
  def get_route_type_filter(app, _) when app in [BusEink, BusShelter], do: [:bus]
  def get_route_type_filter(GlEink, _), do: [:light_rail]
  # Ashmont should not show Mattapan alerts for PreFare or Dup
  def get_route_type_filter(app, "place-asmnl") when app in [PreFare, Dup], do: [:subway]
  def get_route_type_filter(PreFare, _), do: [:light_rail, :subway]
  def get_route_type_filter(Triptych, _), do: [:light_rail, :subway]
  # WTC is a special bus-only case
  def get_route_type_filter(Dup, "place-wtcst"), do: [:bus]
  def get_route_type_filter(Dup, _), do: [:light_rail, :subway]

  @spec upstream_stop_id_set(String.t(), list(list(id()))) :: MapSet.t(id())
  def upstream_stop_id_set(stop_id, stop_sequences) do
    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_before(stop_sequence, stop_id) end)
    |> MapSet.new()
  end

  @spec downstream_stop_id_set(String.t(), list(list(id()))) :: MapSet.t(id())
  def downstream_stop_id_set(stop_id, stop_sequences) do
    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_after(stop_sequence, stop_id) end)
    |> MapSet.new()
  end

  def on_glx?(stop_id) do
    stop_id in Enum.map(@medford_tufts_branch_stops ++ @union_square_branch_stops, &elem(&1, 0))
  end

  def on_ashmont_branch?(stop_id) do
    stop_id in Enum.map(@red_line_ashmont_branch_stops, &elem(&1, 0))
  end

  def on_braintree_branch?(stop_id) do
    stop_id in Enum.map(@red_line_braintree_branch_stops, &elem(&1, 0))
  end

  defp fetch_tagged_stop_sequences_by_app(app, stop_id, _routes_at_stop)
       when app in [BusEink, BusShelter, GlEink] do
    RoutePattern.fetch_tagged_stop_sequences_through_stop(stop_id)
  end

  defp fetch_tagged_stop_sequences_by_app(app, stop_id, routes_at_stop)
       when app in [Dup, Triptych] do
    route_ids = Route.route_ids(routes_at_stop)
    RoutePattern.fetch_tagged_parent_station_sequences_through_stop(stop_id, route_ids)
  end

  defp fetch_tagged_stop_sequences_by_app(app, stop_id, routes_at_stop)
       when app == PreFare do
    route_ids = Route.route_ids(routes_at_stop)

    # We limit results to canonical route patterns only--no stop sequences for nonstandard patterns.
    RoutePattern.fetch_tagged_parent_station_sequences_through_stop(stop_id, route_ids, true)
  end
end
