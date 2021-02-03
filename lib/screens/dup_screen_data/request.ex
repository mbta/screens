defmodule Screens.DupScreenData.Request do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Dup.Section
  alias Screens.Config.Dup.Section.Headway
  alias Screens.Departures.Departure
  alias Screens.DupScreenData.Response
  alias Screens.SignsUiConfig

  # Filters for the types of alerts we care about
  @alert_route_types ~w[light_rail subway]a
  @alert_effects MapSet.new(~w[delay shuttle suspension station_closure]a)

  @branch_stations ["place-kencl", "place-jfk", "place-coecl"]
  @branch_terminals [
    "Boston College",
    "Cleveland Circle",
    "Riverside",
    "Heath Street",
    "Ashmont",
    "Braintree"
  ]

  def fetch_alerts(stop_ids, route_ids) do
    opts = [
      stop_ids: stop_ids,
      route_ids: route_ids,
      route_types: @alert_route_types
    ]

    opts
    |> Alert.fetch()
    |> Enum.filter(&relevant?/1)
  end

  def fetch_sections_data([_, _] = sections_with_alerts, current_time) do
    sections_data =
      sections_with_alerts
      |> Task.async_stream(&fetch_section_data(&1, 2, current_time))
      |> Enum.map(fn {:ok, data} -> data end)

    if Enum.any?(sections_data, fn data -> data == :error end) do
      :error
    else
      {:ok, Enum.map(sections_data, fn {:ok, data} -> data end)}
    end
  end

  def fetch_sections_data([section_with_alert], current_time) do
    case fetch_section_data(section_with_alert, 4, current_time) do
      {:ok, data} -> {:ok, [data]}
      :error -> :error
    end
  end

  defp fetch_section_data(
         {%Section{pill: pill, headway: %Headway{override: {lo, hi}}}, _section_alert},
         num_rows,
         _current_time
       ) do
    {:ok, %{pill: pill, headway: Response.render_headway_lines(pill, {lo, hi}, num_rows)}}
  end

  defp fetch_section_data(
         {%Section{stop_ids: stop_ids, route_ids: route_ids, pill: pill, headway: headway} =
            section, section_alert},
         num_rows,
         current_time
       ) do
    case fetch_headway_mode(section, headway, section_alert, current_time) do
      {:active, {lo, hi}} ->
        {:ok, %{pill: pill, headway: Response.render_headway_lines(pill, {lo, hi}, num_rows)}}

      :inactive ->
        fetch_section_departures(stop_ids, route_ids, pill, num_rows)
    end
  end

  defp temporary_terminal?(section_alert) do
    # NB: There aren't currently any DUPs at permanent terminals, so we assume all
    # terminals are temporary. In the future, we'll need to check that the boundary
    # isn't a normal terminal.
    match?([%{region: :boundary}], section_alert)
  end

  defp branch_station?(stop_ids) do
    case stop_ids do
      [parent_station_id] -> parent_station_id in MapSet.new(@branch_stations)
      _ -> false
    end
  end

  defp branch_alert?(section_alert) do
    case section_alert do
      [%{headsign: headsign}] -> headsign in MapSet.new(@branch_terminals)
      _ -> false
    end
  end

  defp fetch_headway_mode(
         %Section{stop_ids: stop_ids},
         %Headway{sign_ids: sign_ids, headway_id: headway_id},
         section_alert,
         current_time
       ) do
    non_branch_temporary_terminal? =
      temporary_terminal?(section_alert) and
        not (branch_station?(stop_ids) and branch_alert?(section_alert))

    signs_ui_headways? = SignsUiConfig.State.all_signs_in_headway_mode?(sign_ids)
    headway_mode? = non_branch_temporary_terminal? or signs_ui_headways?

    if headway_mode? do
      time_ranges = SignsUiConfig.State.time_ranges(headway_id)
      current_time_period = Screens.Util.time_period(current_time)

      case time_ranges do
        %{^current_time_period => {lo, hi}} ->
          {:active, {lo, hi}}

        _ ->
          :inactive
      end
    else
      :inactive
    end
  end

  defp fetch_section_departures(stop_ids, route_ids, pill, num_rows) do
    query_params = %{stop_ids: stop_ids, route_ids: route_ids}
    include_schedules? = Enum.member?([:cr, :ferry], pill)

    case Departure.fetch(query_params, include_schedules?) do
      {:ok, departures} ->
        section_departures =
          departures
          |> Enum.map(&Map.from_struct/1)
          |> Enum.sort_by(& &1.time)
          |> Enum.take(num_rows)

        {:ok, %{departures: section_departures, pill: pill}}

      :error ->
        :error
    end
  end

  defp relevant?(alert) do
    Alert.happening_now?(alert) and
      alert.effect in @alert_effects and
      effect_specific_conditions?(alert)
  end

  defp effect_specific_conditions?(%Alert{effect: :delay} = alert) do
    Alert.high_severity?(alert)
  end

  defp effect_specific_conditions?(_), do: true
end
