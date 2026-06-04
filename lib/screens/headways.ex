defmodule Screens.Headways do
  @moduledoc """
  Looks up headway values to be displayed on screens for stops with frequent service, for example
  when no live departures are available ("Trains every X-Y minutes").
  """

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
    green_trunk: [70150..70159, 70196..70208, 70501..70502, 71150..71151],
    mattapan_trunk: [70261..70261, 70263..70276],
    orange_trunk: [70001..70036, 70278..70279],
    red_ashmont: [70085..70094],
    red_braintree: [70095..70105],
    red_trunk: [70061..70061, 70063..70084],
    silver_seaport: [247..247, 17_091..17_095, 27_092..27_092, 30_249..30_251, 31_255..31_259],
    silver_chelsea: [7096..7097, 74_611..74_617, 74_630..74_637]
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

  @spec headway_key(Stop.id()) :: SignsUi.headway_key() | nil
  for {key, ranges} <- @stops, range <- ranges, stop_id <- range do
    defp headway_key(unquote(to_string(stop_id))), do: unquote(to_string(key))
  end

  defp headway_key(_stop_id), do: nil

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
