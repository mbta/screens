defmodule Screens.Headways do
  @moduledoc """
  Looks up headway values to be displayed on screens for stops with frequent service, for example
  when no live departures are available ("Trains every X-Y minutes").
  """

  alias Screens.Routes.Route
  alias Screens.SignsUiConfig.Cache, as: SignsUi
  alias Screens.Stops.Stop
  alias Screens.Util

  # Compact mapping of stop IDs to headway keys, leaning on the fact that subway stop IDs happen
  # to be numeric and often contiguous as we "traverse" the line in a given direction.
  @stops %{
    blue_trunk: [70_038..70_060],
    glx_medford: [70_505..70_514],
    glx_union: [70_503..70_504],
    green_b: [
      70_106..70_107,
      70_110..70_117,
      70_120..70_121,
      70_124..70_131,
      70_134..70_135,
      70_144..70_149,
      170_136..170_137,
      170_140..170_141
    ],
    green_c: [70_211..70_220, 70_223..70_238],
    green_d: [70_160..70_183, 70_186..70_187],
    green_e: [70_239..70_258, 70_260..70_260],
    green_trunk: [70_151..70_159, 70_196..70_208, 70_501..70_502, 71_150..71_151],
    mattapan_trunk: [70_261..70_261, 70_263..70_276],
    orange_trunk: [70_001..70_036, 70_278..70_279],
    red_ashmont: [70_085..70_094],
    red_braintree: [70_095..70_105],
    red_trunk: [70_061..70_061, 70_063..70_084]
  }

  @sl_stops %{
    sl_one: [17_091..17_095, 27_092..27_092],
    sl_two: [30_250..30_251, 31_255..31_259],
    sl_three: [7096..7097, 74_630..74_637]
  }

  # Mapping of parent station IDs to headway keys, for stations with a single unambiguous key.
  # For brevity, omits the "place-" prefix which is currently common to all parent station IDs.
  @stations %{
    blue_trunk: ~w[wondl rbmnl bmmnl sdmnl orhte wimnl mvbcl aqucl bomnl],
    glx_medford: ~w[mdftf balsq mgngl gilmn esomr],
    glx_union: ~w[unsqu],
    green_b: ~w[
      bland
      buest
      bucen
      amory
      babck
      brico
      harvd
      grigg
      alsgr
      wrnst
      wascm
      sthld
      chswk
      chill
      sougr
      lake
    ],
    green_c: ~w[
      smary
      hwsst
      kntst
      stpul
      cool
      sumav
      bndhl
      fbkst
      bcnwa
      tapst
      denrd
      engav
      clmnl
    ],
    green_d: ~w[
      fenwy
      longw
      bvmnl
      brkhl
      bcnfd
      rsmnl
      chhil
      newto
      newtn
      eliot
      waban
      woodl
      river
    ],
    green_e: ~w[
      prmnl
      symcl
      nuniv
      mfa
      lngmd
      brmnl
      fenwd
      mispk
      rvrwy
      bckhl
      hsmnl
    ],
    green_trunk: ~w[lech spmnl boyls armnl coecl hymnl kencl],
    orange_trunk: ~w[
      ogmnl
      mlmnl
      welln
      astao
      sull
      ccmnl
      chncl
      tumnl
      bbsta
      masta
      rugg
      rcmnl
      jaksn
      sbmnl
      grnst
      forhl
    ],
    red_ashmont: ~w[shmnl fldcr smmnl asmnl],
    red_braintree: ~w[nqncy wlsta qnctr qamnl brntn],
    red_trunk: ~w[alfcl davis portr harsq cntsq knncl chmnl sstat brdwy andrw jfk],
    sl_three: ~w[estav boxdt belsq chels]
  }

  # Mapping of parent station and route IDs to headway keys, for parent stations which serve more
  # than one line.
  @multi_stations %{
    blue_trunk: {~w[Blue], ~w[state gover aport]},
    green_trunk: {~w[Green-B Green-C Green-D Green-E], ~w[north haecl gover pktrm]},
    orange_trunk: {~w[Orange], ~w[north haecl state dwnxg]},
    red_trunk: {~w[Red], ~w[pktrm dwnxg]},
    sl_one: {~w[741], ~w[conrd wtcst crtst sstat]},
    sl_two: {~w[742], ~w[conrd wtcst crtst sstat]},
    sl_three: {~w[743], ~w[conrd wtcst crtst sstat aport]},
    sl_way: {~w[746], ~w[conrd wtcst crtst sstat]}
  }

  @type range :: {low :: pos_integer(), high :: pos_integer()}

  @doc """
  Gets headway values for a stop. The stop should be a stopping location (`location_type == 0`).
  Returns `nil` otherwise, or if no headways are configured for the stop or time period.
  """
  @callback get(Stop.id()) :: range() | nil
  @callback get(Stop.id(), DateTime.t()) :: range() | nil
  def get(stop_id, at \\ DateTime.utc_now()) do
    case headway_key(stop_id) do
      nil -> nil
      key -> key |> SignsUi.headways() |> Map.get(period(at))
    end
  end

  @doc """
  Gets headway values for a stop, with a route provided to disambiguate when the stop is a parent
  station served by multiple routes.

  ⚠️ Included for compatibility with existing DUP departures logic. Prefer `get/2`.
  """
  @callback get_with_route(Stop.id(), Route.id()) :: range() | nil
  @callback get_with_route(Stop.id(), Route.id(), DateTime.t()) :: range() | nil
  def get_with_route(stop_id, route_id, at \\ DateTime.utc_now()) do
    case headway_key(stop_id, route_id) do
      nil -> nil
      key -> key |> SignsUi.headways() |> Map.get(period(at))
    end
  end

  @spec headway_key(Stop.id()) :: SignsUi.headway_key() | nil
  @spec headway_key(Stop.id(), Route.id()) :: SignsUi.headway_key() | nil
  for {key, ranges} <- @stops, range <- ranges, stop_id <- range do
    defp headway_key(unquote(to_string(stop_id))), do: unquote(to_string(key))
    defp headway_key(unquote(to_string(stop_id)), _route_id), do: unquote(to_string(key))
  end

  for {_, ranges} <- @sl_stops, range <- ranges, stop_id <- range do
    defp headway_key(unquote(to_string(stop_id)), route_id),
      do: silver_line_route_headway_key(route_id)
  end

  for {key, {route_ids, stations}} <- @multi_stations,
      route_id <- route_ids,
      station <- stations do
    defp headway_key("place-" <> unquote(station), unquote(route_id)), do: unquote(to_string(key))
  end

  for {key, stations} <- @stations, station <- stations do
    defp headway_key("place-" <> unquote(station), _route_id), do: unquote(to_string(key))
  end

  defp headway_key(_stop_id), do: nil
  defp headway_key(_stop_id, _route_id), do: nil

  @spec period(DateTime.t()) :: :peak | :off_peak | :saturday | :sunday
  defp period(datetime) do
    local_dt = Util.to_eastern(datetime)
    day_of_week = local_dt |> Util.service_date() |> Date.day_of_week()

    time = {local_dt.hour, local_dt.minute}
    am_peak? = time >= {7, 0} and time < {9, 0}
    pm_peak? = time >= {16, 0} and time <= {18, 30}
    peak_time? = am_peak? or pm_peak?

    case {day_of_week, peak_time?} do
      {6, _} -> :saturday
      {7, _} -> :sunday
      {_, true} -> :peak
      {_, false} -> :off_peak
    end
  end

  defp silver_line_route_headway_key("741"), do: "sl_one"
  defp silver_line_route_headway_key("742"), do: "sl_two"
  defp silver_line_route_headway_key("743"), do: "sl_three"
  defp silver_line_route_headway_key(_), do: nil
end
