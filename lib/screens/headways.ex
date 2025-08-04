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
    red_trunk: [70061..70061, 70063..70084],
    silver_seaport: [247..247, 17_091..17_095, 27_092..27_092, 30_249..30_251, 31_255..31_259],
    silver_chelsea: [7096..7097, 74_630..74_637]
  }

  # Mapping of parent station IDs and route IDs to headway keys. For brevity, omits the "place-"
  # prefix which is currently common to all parent station IDs.
  @stations %{
    blue_trunk: {
      ~w[Blue],
      ~w[wondl rbmnl bmmnl sdmnl orhte wimnl aport mvbcl aqucl state gover bomnl]
    },
    glx_medford: {~w[Green-E], ~w[mdftf balsq mgngl gilmn esomr]},
    glx_union: {~w[Green-D], ~w[unsqu]},
    green_b: {
      ~w[Green-B],
      ~w[
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
      ]
    },
    green_c: {
      ~w[Green-C],
      ~w[smary hwsst kntst stpul cool sumav bndhl fbkst bcnwa tapst denrd engav clmnl]
    },
    green_d: {
      ~w[Green-D],
      ~w[fenwy longw bvmnl brkhl bcnfd rsmnl chhil newto newtn eliot waban woodl river]
    },
    green_e: {
      ~w[Green-E],
      ~w[prmnl symcl nuniv mfa lngmd brmnl fenwd mispk rvrwy bckhl hsmnl]
    },
    # Not all of these stations are served by all Green Line branches, but "trunk" is the most
    # granular division of the Green Line we have to work with
    green_trunk: {
      ~w[Green-B Green-C Green-D Green-E],
      ~w[lech spmnl north haecl gover pktrm boyls armnl coecl hymnl kencl]
    },
    orange_trunk: {
      ~w[Orange],
      ~w[
        ogmnl
        mlmnl
        welln
        astao
        sull
        ccmnl
        north
        haecl
        state
        dwnxg
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
      ]
    },
    red_trunk: {
      ~w[Red],
      ~w[alfcl davis portr harsq cntsq knncl chmnl pktrm dwnxg sstat brdwy andrw jfk]
    },
    red_ashmont: {~w[Red], ~w[shmnl fldcr smmnl asmnl]},
    red_braintree: {~w[Red], ~w[nqncy wlsta qnctr qamnl brntn]},
    silver_seaport: {~w[741 742 746], ~w[conrd wtcst crtst sstat]},
    silver_chelsea: {~w[743], ~w[conrd wtcst crtst sstat aport estav boxdt belsq chels]}
  }

  # Mapping of stops and route IDs to headway keys for the Silver Line,
  # for stops which serve more than one route.
  @sl_stops %{
    # congress_st_at_wtc 17_096
    silver_seaport: {~w[741 742 746], ~w[17096]},
    silver_chelsea: {~w[743], ~w[17096]}
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

  for {key, {route_ids, stations}} <- @stations,
      route_id <- route_ids,
      station <- stations do
    defp headway_key("place-" <> unquote(station), unquote(route_id)), do: unquote(to_string(key))
  end

  for {key, {route_ids, stations}} <- @sl_stops,
      route_id <- route_ids,
      station <- stations do
    defp headway_key(unquote(station), unquote(route_id)), do: unquote(to_string(key))
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
end
