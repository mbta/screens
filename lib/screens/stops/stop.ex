defmodule Screens.Stops.Stop do
  @moduledoc """
  This file handles involves stop-related fetching / enrichment.
  For a while, all stop-related data was fetched from the API, until we needed to provide consistent
  abbreviations in the reconstructed alert. Now it's valuable to have a local copy of these stop sequences.
  A lot of our code still collects these sequences from the API, though, whether in functions here
  or in functions in `route_pattern.ex` (see fetch_parent_station_sequences_through_stop).
  So there's inconsistent use of this local data.
  """

  alias Screens.Routes
  alias Screens.Stops.StationsWithRoutesAgent
  alias Screens.V3Api

  defstruct id: nil,
            name: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          name: String.t()
        }

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

  def fetch_routes_serving_stop(station_id, headers \\ [], get_json_fn \\ &V3Api.get_json/5) do
    case get_json_fn.(
           "routes",
           %{
             "filter[stop]" => station_id
           },
           headers,
           [],
           true
         ) do
      {:ok, %{"data" => data}, headers} ->
        date =
          headers
          |> Enum.into(%{})
          |> Map.get("last-modified")

        routes =
          data
          |> Enum.map(fn route -> Routes.Parser.parse_route(route) end)

        StationsWithRoutesAgent.put(station_id, routes, date)

        {:ok, routes}

      :not_modified ->
        :not_modified

      _ ->
        :error
    end
  end

  def create_station_with_routes_map(station_id) do
    case StationsWithRoutesAgent.get(station_id) do
      {routes, date} ->
        case fetch_routes_serving_stop(station_id, [{"if-modified-since", date}]) do
          {:ok, new_routes} -> new_routes
          :not_modified -> routes
          :error -> []
        end

      nil ->
        case fetch_routes_serving_stop(station_id) do
          {:ok, new_routes} -> new_routes
          :error -> []
        end
    end
  end

  def fetch_stop_name(stop_id) do
    case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_id}) do
      {:ok, %{"data" => [stop_data]}} ->
        %{"attributes" => %{"name" => stop_name}} = stop_data
        stop_name

      _ ->
        nil
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
    @route_stop_sequences |> Map.get("Green") |> hd() |> Enum.map(&elem(&1, 0)) |> MapSet.new()
  end

  def stop_id_to_name(route_id) do
    @route_stop_sequences
    |> Map.get(route_id)
    |> Enum.flat_map(fn x -> x end)
    |> Enum.uniq()
    |> Enum.into(%{})
  end

  def get_all_routes_stop_sequence() do
    @route_stop_sequences
  end

  def get_all_subway_stops() do
    @blue_line_stops ++ @orange_line_stops ++ @red_line_trunk_stops ++ @red_line_ashmont_branch_stops ++
    @red_line_braintree_branch_stops ++ @green_line_b_stops ++ @green_line_c_stops ++ @green_line_d_stops ++ @green_line_e_stops ++ @green_line_trunk_stops
  end
end
