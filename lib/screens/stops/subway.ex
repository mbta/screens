defmodule Screens.Stops.Subway do
  @moduledoc """
  Functions that operate on a hard-coded copy of the "canonical" parent station sequences for
  subway lines. Also encodes abbreviated forms of the stations' names, e.g. for use in disruption
  diagrams.
  """

  alias Screens.Alerts.InformedEntity
  alias Screens.Routes.Route
  alias Screens.Stops.Stop

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

  @mattapan_stops [
    {"place-asmnl", {"Ashmont", "Ashmont"}},
    {"place-cedgr", {"Cedar Grove", "Cedar Grove"}},
    {"place-butlr", {"Butler", "Butler"}},
    {"place-miltt", {"Milton", "Milton"}},
    {"place-cenav", {"Central Avenue", "Central Ave"}},
    {"place-valrd", {"Valley Road", "Valley Rd"}},
    {"place-capst", {"Capen Street", "Capen St"}},
    {"place-matt", {"Mattapan", "Mattapan"}}
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
    "Mattapan" => [@mattapan_stops],
    "Green-B" => [@green_line_b_stops],
    "Green-C" => [@green_line_c_stops],
    "Green-D" => [@green_line_d_stops],
    "Green-E" => [@green_line_e_stops],
    "Green" => [@green_line_trunk_stops]
  }

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  @type station :: {Stop.id(), station_names()}
  @type station_names :: {full :: String.t(), abbreviated :: String.t()}

  def all_stop_sequences, do: @route_stop_sequences
  def gl_trunk_stops, do: @green_line_trunk_stops
  def rl_trunk_stops, do: @red_line_trunk_stops

  @spec ashmont_branch_stop?(Stop.id()) :: boolean()
  def ashmont_branch_stop?(stop_id) do
    stop_id in Enum.map(@red_line_ashmont_branch_stops, &elem(&1, 0))
  end

  @spec braintree_branch_stop?(Stop.id()) :: boolean()
  def braintree_branch_stop?(stop_id) do
    stop_id in Enum.map(@red_line_braintree_branch_stops, &elem(&1, 0))
  end

  @spec gl_stop_sequences() :: [[Stop.id()]]
  def gl_stop_sequences, do: Enum.map(@green_line_branches, &route_stop_sequence/1)

  @spec gl_stops_west_of_copley() :: MapSet.t(Stop.id())
  def gl_stops_west_of_copley do
    gl_stop_sequences()
    |> Enum.flat_map(fn stop_sequence ->
      [_copley | west_of_copley] = Enum.drop_while(stop_sequence, &(&1 != "place-coecl"))
      west_of_copley
    end)
    |> MapSet.new()
  end

  @spec glx_stop?(Stop.id()) :: boolean()
  def glx_stop?(stop_id) do
    stop_id in Enum.map(@medford_tufts_branch_stops ++ @union_square_branch_stops, &elem(&1, 0))
  end

  @spec stop_index_for_informed_entity(InformedEntity.t(), [station()]) :: non_neg_integer() | nil
  def stop_index_for_informed_entity(%{stop: stop_id}, stop_sequence) do
    Enum.find_index(stop_sequence, fn {station_id, _} -> station_id == stop_id end)
  end

  @spec stop_on_route?(Stop.id(), [station()]) :: boolean()
  def stop_on_route?(stop_id, stop_sequence) when not is_nil(stop_id) do
    Enum.any?(stop_sequence, fn {station_id, _} -> station_id == stop_id end)
  end

  @spec stop_sequence_containing_informed_entities([InformedEntity.t()], Route.id()) ::
          [station()] | nil
  def stop_sequence_containing_informed_entities(informed_entities, "Green") do
    Enum.find_value(@green_line_branches, fn branch ->
      stop_sequence_containing_informed_entities(informed_entities, branch)
    end)
  end

  def stop_sequence_containing_informed_entities(informed_entities, route_id) do
    stop_sequences = Map.get(@route_stop_sequences, route_id)
    Enum.find(stop_sequences, &sequence_match?(&1, informed_entities))
  end

  @spec route_stop_names(Route.id()) :: %{Stop.id() => station_names()}
  def route_stop_names(route_id) do
    @route_stop_sequences
    |> Map.get(route_id)
    |> Enum.flat_map(fn x -> x end)
    |> Enum.uniq()
    |> Enum.into(%{})
  end

  @spec route_stop_sequence(Route.id()) :: [Stop.id()]
  def route_stop_sequence(route_id) do
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
end
