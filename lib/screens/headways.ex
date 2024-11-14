defmodule Screens.Headways do
  @moduledoc """
  Looks up headway values to be displayed on screens for stops with frequent service, for example
  when no live departures are available ("Trains every X-Y minutes").
  """

  alias Screens.Routes.Route
  alias Screens.SignsUiConfig.Cache, as: SignsUi
  alias Screens.Stops.Stop

  # Compact mapping of stop IDs to headway keys, leaning on the fact that subway stop IDs happen
  # to be numeric and often contiguous as we "traverse" the line in a given direction.
  @stops %{
    blue_trunk: [70038..70060],
    glx_medford: [70505..70514],
    glx_union: [70503..70504],
    green_b: [
      70106..70107,
      70110..70117,
      70120..70121,
      70124..70131,
      70134..70135,
      70144..70149,
      170_136..170_137,
      170_140..170_141
    ],
    green_c: [70211..70220, 70223..70238],
    green_d: [70160..70183, 70186..70187],
    green_e: [70239..70258, 70260..70260],
    green_trunk: [70151..70159, 70196..70208, 70501..70502, 71150..71151],
    mattapan_trunk: [70261..70261, 70263..70276],
    orange_trunk: [70001..70036, 70278..70279],
    red_ashmont: [70085..70094],
    red_braintree: [70095..70105],
    red_trunk: [70061..70061, 70063..70084]
  }

  # Mapping of parent station IDs to headway keys, for stations with a single unambiguous key.
  # For brevity, omits the "place-" prefix which is currently common to all parent station IDs.
  @stations %{
    blue_trunk: ~w[wondl rbmnl bmmnl sdmnl orhte wimnl aport mvbcl aqucl bomnl],
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
    red_trunk: ~w[alfcl davis portr harsq cntsq knncl chmnl sstat brdwy andrw jfk]
  }

  # Mapping of parent station and route IDs to headway keys, for parent stations which serve more
  # than one line.
  @multi_stations %{
    blue_trunk: {~w[Blue], ~w[state gover]},
    green_trunk: {~w[Green-B Green-C Green-D Green-E], ~w[north haecl gover pktrm]},
    orange_trunk: {~w[Orange], ~w[north haecl state dwnxg]},
    red_trunk: {~w[Red], ~w[pktrm dwnxg]}
  }

  @type range :: {low :: pos_integer(), high :: pos_integer()}

  @doc """
  Gets headway values for a stop. The stop should be a stopping location (`location_type == 0`).
  Returns `nil` otherwise, or if no headways are configured for the stop.
  """
  @spec get(Stop.id()) :: range() | nil
  @spec get(Stop.id(), DateTime.t()) :: range() | nil
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

  for {key, stations} <- @stations, station <- stations do
    defp headway_key("place-" <> unquote(station), _route_id), do: unquote(to_string(key))
  end

  for {key, {route_ids, stations}} <- @multi_stations,
      route_id <- route_ids,
      station <- stations do
    defp headway_key("place-" <> unquote(station), unquote(route_id)), do: unquote(to_string(key))
  end

  defp headway_key(_stop_id), do: nil
  defp headway_key(_stop_id, _route_id), do: nil

  @spec period(DateTime.t()) :: :peak | :off_peak | :saturday | :sunday
  defp period(datetime) do
    local_dt = DateTime.shift_zone!(datetime, "America/New_York")

    # Subtract 3 hours, since the service day starts/ends at 3:00 AM
    day_of_week = local_dt |> DateTime.add(-3, :hour) |> Date.day_of_week()

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
end
