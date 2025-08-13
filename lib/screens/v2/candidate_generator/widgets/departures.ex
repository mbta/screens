defmodule Screens.V2.CandidateGenerator.Widgets.Departures do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService, OvernightDepartures}
  alias ScreensConfig.{Departures, FreeTextLine, Screen}
  alias ScreensConfig.Departures.Filters.RouteDirections
  alias ScreensConfig.Departures.Filters.RouteDirections.RouteDirection
  alias ScreensConfig.Departures.{Filters, Query, Section}
  alias ScreensConfig.Screen.{BusEink, BusShelter, Busway, GlEink, PreFare}

  @type options :: [
          departure_fetch_fn: Departure.fetch(),
          disabled_modes_fn: (-> RouteType.t()),
          post_process_fn: (Departure.result(), Screen.t() -> Departure.result() | :overnight),
          route_fetch_fn: (Route.params() -> {:ok, [Route.t()]} | :error),
          now: DateTime.t()
        ]

  @type widget ::
          DeparturesNoData.t()
          | DeparturesNoService.t()
          | DeparturesWidget.t()
          | OvernightDepartures.t()

  @spec departures_instances(Screen.t(), options()) :: [widget()]
  def departures_instances(%Screen{app_params: %app{}} = config, now, options \\ [])
      when app in [BusEink, BusShelter, Busway, GlEink, PreFare] do
    disabled_modes =
      Keyword.get(options, :disabled_modes_fn, &Screens.Config.Cache.disabled_modes/0).()

    if screen_devops_mode(config) in disabled_modes do
      [%DeparturesNoData{screen: config, show_alternatives?: false}]
    else
      do_departures_instances(
        config,
        disabled_modes,
        Keyword.get(options, :departure_fetch_fn, &Departure.fetch/2),
        Keyword.get(options, :post_process_fn, fn results, _config -> results end),
        Keyword.get(options, :route_fetch_fn, &Route.fetch/1),
        now
      )
    end
  end

  defp do_departures_instances(%Screen{app_params: %{departures: departures}}, _, _, _, _, _)
       when is_nil(departures) or departures.sections == [] do
    []
  end

  defp do_departures_instances(
         %Screen{app_params: %{departures: %Departures{sections: sections}}, app_id: app_id} =
           config,
         disabled_modes,
         departure_fetch_fn,
         post_process_fn,
         route_fetch_fn,
         now
       ) do
    has_multiple_sections = match?([_, _ | _], sections)

    sections_data =
      sections
      |> Task.async_stream(
        &%{
          section: &1,
          result:
            &1
            |> fetch_section_departures(disabled_modes, departure_fetch_fn)
            |> post_process_fn.(config)
            |> post_process_no_data(&1, has_multiple_sections, route_fetch_fn)
        },
        timeout: 30_000
      )
      |> Enum.map(fn {:ok, section_data} -> section_data end)

    departures_instance =
      cond do
        Enum.any?(sections_data, &(&1.result == :error)) ->
          %DeparturesNoData{screen: config, show_alternatives?: true}

        match?([%{result: :overnight}], sections_data) ->
          %OvernightDepartures{}

        match?([%{result: {:ok, []}}], sections_data) and app_id == :bus_eink_v2 ->
          %DeparturesNoService{screen: config}

        true ->
          sections =
            Enum.map(sections_data, fn
              %{
                section: %Section{header: header, layout: layout, grouping_type: grouping_type},
                result: result
              } ->
                %NormalSection{
                  rows: normal_section_rows(result),
                  layout: layout,
                  header: header,
                  grouping_type: grouping_type
                }
            end)

          slot_names =
            case config do
              %Screen{app_params: %PreFare{}} -> [:main_content_left]
              _ -> []
            end

          %DeparturesWidget{screen: config, sections: sections, now: now, slot_names: slot_names}
      end

    [departures_instance]
  end

  # When a section has no departures on a screen with multiple sections and is not designated as
  # `header_only`, populate it with a "no data" entry. This may include a "representative" route
  # for the section, used to determine an icon to display alongside the message.
  #
  # NOTE: Assumes any given section is configured such that it only displays departures from a
  # single route-type-or-subway-line. If there would be more than one route-type-or-subway-line,
  # one is picked arbitrarily.
  defp post_process_no_data(
         {:ok, []},
         %Section{
           query: %Query{
             params: %Query.Params{
               direction_id: direction_id,
               route_ids: route_ids,
               route_type: route_type,
               stop_ids: stop_ids
             }
           },
           header_only: false
         },
         true = _has_multiple_sections,
         route_fetch_fn
       ) do
    fetch_params =
      Map.reject(
        %{
          limit: 1,
          ids: route_ids,
          route_types: if(route_type, do: [route_type], else: []),
          stop_ids: stop_ids
        },
        fn {_key, value} -> value == [] end
      )

    case route_fetch_fn.(fetch_params) do
      {:ok, [route | _]} -> {:no_data, route, direction_id}
      _ -> :no_data
    end
  end

  defp post_process_no_data(fetch_result, _, _, _), do: fetch_result

  defp normal_section_rows({:ok, departures}), do: departures

  defp normal_section_rows({:no_data, route, direction_id}) when direction_id in [0, 1] do
    [
      %FreeTextLine{
        icon: Route.icon(route),
        text: [
          route
          |> Route.normalized_direction_names()
          |> Enum.at(direction_id, "")
          |> no_departures_message()
        ]
      }
    ]
  end

  defp normal_section_rows({:no_data, route, _both}) do
    [%FreeTextLine{icon: Route.icon(route), text: [no_departures_message()]}]
  end

  defp normal_section_rows(:no_data) do
    [%FreeTextLine{icon: nil, text: [no_departures_message()]}]
  end

  defp no_departures_message, do: "No departures currently available"
  defp no_departures_message(direction_name), do: "No #{direction_name} departures available"

  @spec fetch_section_departures(Section.t()) :: Departure.result()
  @spec fetch_section_departures(Section.t(), [RouteType.t()]) :: Departure.result()
  @spec fetch_section_departures(Section.t(), [RouteType.t()], Departure.fetch()) ::
          Departure.result()
  @spec fetch_section_departures(Section.t(), [RouteType.t()], Departure.fetch(), DateTime.t()) ::
          Departure.result()
  def fetch_section_departures(
        _,
        disabled_route_types \\ [],
        departure_fetch_fn \\ &Departure.fetch/2,
        now \\ DateTime.utc_now()
      )

  def fetch_section_departures(%Section{header_only: true}, _, _, _) do
    {:ok, []}
  end

  def fetch_section_departures(
        %Section{
          query: %Query{opts: opts, params: params},
          filters: filters,
          bidirectional: is_bidirectional,
          grouping_type: grouping_type
        },
        disabled_route_types,
        departure_fetch_fn,
        now
      ) do
    fetch_params = Map.from_struct(params)
    fetch_opts = opts |> Map.from_struct() |> Keyword.new()

    with {:ok, departures} <- departure_fetch_fn.(fetch_params, fetch_opts) do
      filtered_departures =
        departures
        |> Enum.reject(&(Departure.route(&1).type in disabled_route_types))
        |> filter_departures(filters, now)

      {:ok,
       cond do
         is_bidirectional -> make_bidirectional(filtered_departures)
         grouping_type == :destination -> sort_by_direction_id(filtered_departures)
         true -> filtered_departures
       end}
    end
  end

  defp filter_departures(
         departures,
         %Filters{max_minutes: max_minutes, route_directions: route_directions},
         now
       ) do
    departures
    |> filter_by_time(max_minutes, now)
    |> filter_by_route_direction(route_directions)
  end

  defp filter_by_time(departures, nil, _now), do: departures

  defp filter_by_time(departures, max_minutes, now) do
    latest_time = DateTime.add(now, max_minutes, :minute)
    Enum.reject(departures, &(DateTime.compare(Departure.time(&1), latest_time) == :gt))
  end

  defp filter_by_route_direction(departures, %RouteDirections{
         action: :include,
         targets: targets
       }) do
    Enum.filter(departures, &departure_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(departures, %RouteDirections{
         action: :exclude,
         targets: targets
       }) do
    Enum.reject(departures, &departure_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(departures, nil) do
    departures
  end

  defp departure_in_route_directions?(d, route_directions) do
    route_direction(d) in route_directions
  end

  defp route_direction(d) do
    %RouteDirection{route_id: Departure.route(d).id, direction_id: Departure.direction_id(d)}
  end

  # "Bidirectional" mode: take only the first departure, and the next departure in the opposite
  # direction from the first, if one exists.
  defp make_bidirectional([]), do: []

  defp make_bidirectional([first | rest]) do
    first_direction = Departure.direction_id(first)

    opposite? =
      Enum.find(rest, Enum.at(rest, 0), fn departure ->
        Departure.direction_id(departure) == 1 - first_direction
      end)

    Enum.reject([first, opposite?], &is_nil/1)
  end

  defp sort_by_direction_id(departures),
    do: Enum.sort_by(departures, &(1 - Departure.direction_id(&1)))

  # Some screen types are always configured to show departures for one specific transit mode. In
  # that case, if the mode is devops-disabled, we immediately know the whole screen should display
  # a "no data" message.
  defp screen_devops_mode(%Screen{app_id: :bus_shelter_v2}), do: :bus
  defp screen_devops_mode(%Screen{app_id: :bus_eink_v2}), do: :bus
  defp screen_devops_mode(%Screen{app_id: :gl_eink_v2}), do: :light_rail
  defp screen_devops_mode(_), do: nil
end
