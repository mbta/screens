defmodule Screens.DupScreenData.Request do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Dup
  alias Screens.Departures.Departure

  # Filters for the types of alerts we care about
  @alert_route_types ~w[light_rail subway]a
  @alert_effects MapSet.new(~w[delay shuttle suspension station_closure]a)

  def fetch_alerts(stop_ids, route_ids) do
    opts = [
      stop_ids: stop_ids,
      route_ids: route_ids,
      route_types: @alert_route_types
    ]

    opts
    |> Alert.fetch()
    |> Enum.filter(fn a ->
      Alert.happening_now?(a) and a.effect in @alert_effects
    end)
  end

  def fetch_sections_data([_, _] = sections) do
    sections_data = Enum.map(sections, &fetch_section_data(&1, 2))

    if Enum.any?(sections_data, fn data -> data == :error end) do
      :error
    else
      {:ok, Enum.map(sections_data, fn {:ok, data} -> data end)}
    end
  end

  def fetch_sections_data([section]) do
    case fetch_section_data(section, 4) do
      {:ok, data} -> {:ok, [data]}
      :error -> :error
    end
  end

  defp fetch_section_data(
         %Dup.Section{stop_ids: stop_ids, route_ids: route_ids, pill: pill},
         num_rows
       ) do
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
end
