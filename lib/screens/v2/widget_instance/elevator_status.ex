defmodule Screens.V2.WidgetInstance.ElevatorStatus do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Elevator.Closure
  alias Screens.Facilities.Facility
  alias Screens.Stops.Stop
  alias Screens.V2.WebLink
  alias ScreensConfig.FreeTextLine

  @enforce_keys ~w[all_station_elevators closures home_station_id]a
  defstruct @enforce_keys ++ [relevant_station_ids: []]

  @type t :: %__MODULE__{
          all_station_elevators: [Facility.t()],
          closures: [Closure.t()],
          home_station_id: Stop.id(),
          relevant_station_ids: MapSet.t(Stop.id())
        }

  defmodule Serialized do
    @moduledoc false

    @derive Jason.Encoder

    @type t :: %__MODULE__{
            status: :ok | :alert | :inaccessible,
            header: String.t(),
            header_size: :large | :medium,
            callout_items: [String.t()],
            footer_lines: [FreeTextLine.t()],
            footer_audio: [String.t()] | nil,
            cta_type: :app | :plain,
            qr_code_url: String.t(),
            # Not included in the serialized form sent to the client; only used by AlertWidget
            alert_ids: [Alert.id()]
          }

    @enforce_keys ~w[status header qr_code_url]a
    defstruct @enforce_keys ++
                [
                  header_size: :medium,
                  callout_items: [],
                  footer_lines: [],
                  footer_audio: [],
                  cta_type: :plain,
                  alert_ids: []
                ]
  end

  defmodule Summary do
    @moduledoc "Builds the '+N other elevators are closed' summary message for the footer."

    alias ScreensConfig.FreeText

    @spec text(non_neg_integer(), non_neg_integer(), String.t()) :: [FreeText.t()]
    def text(with_alts, without_alts, url) do
      List.flatten([
        do_text(with_alts + without_alts, without_alts),
        ["Check your trip at", %{format: :bold, text: url}]
      ])
    end

    defp do_text(total, without_alts) when without_alts > 0 and total == without_alts do
      [
        "#{n_are_closed(total)},",
        %{format: :bold, text: "which #{have(total)} no #{alternative_paths(0)}."}
      ]
    end

    defp do_text(total, without_alts) when without_alts > 0 do
      [
        "#{n_are_closed(total)},",
        %{
          format: :bold,
          text: "including #{without_alts} without #{alternative_paths(without_alts)}."
        }
      ]
    end

    defp do_text(total, 0 = _without_alts) when total > 0 do
      [
        %{format: :bold, text: n_are_closed(total)},
        "(which #{have(total)} #{alternative_paths(total)})."
      ]
    end

    defp do_text(0 = _total, 0 = _without_alts), do: []

    defp alternative_paths(num),
      do: "#{if_one(num, "an ")}in-station alternative path#{if_many(num, "s")}"

    defp have(num), do: if_many(num, "have", "has")

    defp n_are_closed(num),
      do: "+#{num} other MBTA elevator#{if_many(num, "s are", " is")} closed"

    defp if_many(num, when_many, when_one \\ ""), do: if(num == 1, do: when_one, else: when_many)
    defp if_one(num, when_one, when_many \\ ""), do: if_many(num, when_many, when_one)
  end

  @app_cta_url "mbta.com/go-access"
  @elevators_url "mbta.com/elevators"
  @trip_planner_url "mbta.com/trip-planner"

  # Each of the following URLs contain a base64-encoded query string value that will populate a
  # trip origin and preselect the "Prefer accessible routes" checkbox in Trip Planner
  @inaccessible_station_urls %{
    "place-bomnl" =>
      "https://#{@trip_planner_url}?utm_source=screens&utm_medium=qr&utm_campaign=no_ele&utm_content=PRE-175&plan=hsQVX3VudXNlZF9kYXRldGltZV90eXBlxADECGRhdGV0aW1lxCAyMDI2LTA3LTE0VDE1OjEwOjE3LjM0OTI3OS0wNDowMMQEZnJvbYTECGxhdGl0dWRly0BFLkE1VHWjxAlsb25naXR1ZGXLwFHD-GoJiRbEBG5hbWXEB0Jvd2RvaW7EB3N0b3BfaWTEC3BsYWNlLWJvbW5sxAVtb2Rlc4nEA0JVU8QEdHJ1ZcQFRkVSUlnEBHRydWXEBFJBSUzEBHRydWXEBlNVQldBWcQEdHJ1ZcQOX3BlcnNpc3RlbnRfaWTEATDEC191bnVzZWRfQlVTxADEDV91bnVzZWRfRkVSUlnEAMQMX3VudXNlZF9SQUlMxADEDl91bnVzZWRfU1VCV0FZxADEAnRvhMQIbGF0aXR1ZGXEAMQJbG9uZ2l0dWRlxADEBG5hbWXEAMQHc3RvcF9pZMQAxAp3aGVlbGNoYWlyxAR0cnVl",
    "place-boyls" =>
      "https://#{@trip_planner_url}?utm_source=screens&utm_medium=qr&utm_campaign=no_ele&utm_content=PRE-154&plan=hsQVX3VudXNlZF9kYXRldGltZV90eXBlxADECGRhdGV0aW1lxCAyMDI2LTA3LTE0VDE1OjA1OjAwLjA3MjAzNy0wNDowMMQEZnJvbYTECGxhdGl0dWRly0BFLS_CZWq-xAlsb25naXR1ZGXLwFHEIj4YaYPEBG5hbWXECEJveWxzdG9uxAdzdG9wX2lkxAtwbGFjZS1ib3lsc8QFbW9kZXOJxANCVVPEBHRydWXEBUZFUlJZxAR0cnVlxARSQUlMxAR0cnVlxAZTVUJXQVnEBHRydWXEDl9wZXJzaXN0ZW50X2lkxAEwxAtfdW51c2VkX0JVU8QAxA1fdW51c2VkX0ZFUlJZxADEDF91bnVzZWRfUkFJTMQAxA5fdW51c2VkX1NVQldBWcQAxAJ0b4TECGxhdGl0dWRlxADECWxvbmdpdHVkZcQAxARuYW1lxADEB3N0b3BfaWTEAMQKd2hlZWxjaGFpcsQEdHJ1ZQ==",
    "place-hymnl" =>
      "https://#{@trip_planner_url}?utm_source=screens&utm_medium=qr&utm_campaign=no_ele&utm_content=PRE-163&plan=hsQVX3VudXNlZF9kYXRldGltZV90eXBlxADECGRhdGV0aW1lxCAyMDI2LTA3LTE0VDE1OjEwOjM3LjA4MTUyOS0wNDowMMQEZnJvbYTECGxhdGl0dWRly0BFLIeYD1XexAlsb25naXR1ZGXLwFHFoDPnjhnEBG5hbWXEF0h5bmVzIENvbnZlbnRpb24gQ2VudGVyxAdzdG9wX2lkxAtwbGFjZS1oeW1ubMQFbW9kZXOJxANCVVPEBHRydWXEBUZFUlJZxAR0cnVlxARSQUlMxAR0cnVlxAZTVUJXQVnEBHRydWXEDl9wZXJzaXN0ZW50X2lkxAEwxAtfdW51c2VkX0JVU8QAxA1fdW51c2VkX0ZFUlJZxADEDF91bnVzZWRfUkFJTMQAxA5fdW51c2VkX1NVQldBWcQAxAJ0b4TECGxhdGl0dWRlxADECWxvbmdpdHVkZcQAxARuYW1lxADEB3N0b3BfaWTEAMQKd2hlZWxjaGFpcsQEdHJ1ZQ=="
  }
  @inaccessible_station_names Map.keys(@inaccessible_station_urls)

  @elevator_hotline "617-222-2828"
  @audio_cta_alternate_path "For an alternate path, call #{@elevator_hotline}."
  @audio_cta_full_list "For a full list of elevator closures, call #{@elevator_hotline}."

  @max_callout_items 4

  @spec serialize(t()) :: Serialized.t()
  def serialize(%__MODULE__{
        all_station_elevators: all_station_elevators,
        closures: closures,
        home_station_id: home_station_id,
        relevant_station_ids: relevant_station_ids
      }) do
    closed_elevator_ids = MapSet.new(closures, fn %Closure{facility: %Facility{id: id}} -> id end)

    # Choose the first "scenario" that applies (ordered highest-priority first). Each function
    # returns a `Serialized` if it does apply or `nil` if it does not.
    Enum.find_value(
      [
        fn -> station_has_no_elevators(home_station_id, all_station_elevators) end,
        fn ->
          closed_here_without_nearby_backups(closures, home_station_id, closed_elevator_ids)
        end,
        fn ->
          closed_elsewhere_without_in_station_backups(
            closures,
            relevant_station_ids,
            closed_elevator_ids
          )
        end,
        fn -> closed_elsewhere_with_in_station_backups(closures) end,
        fn -> all_working_or_closed_with_nearby_backups(closures) end
      ],
      & &1.()
    )
  end

  def serialize_to_map(%__MODULE__{} = widget),
    do: widget |> serialize() |> Map.from_struct() |> Map.delete(:alert_ids)

  @spec station_has_no_elevators(Stop.id(), [Facility.t()]) :: Serialized.t()
  defp station_has_no_elevators(station_id, all_elevators_at_station)
       when all_elevators_at_station == [] and station_id in @inaccessible_station_names do
    %Serialized{
      status: :inaccessible,
      header: "This station is not accessible.",
      footer_lines:
        footer_lines([
          [
            "To plan an accessible trip, go to",
            %{format: :bold, text: "#{@trip_planner_url}"}
          ]
        ]),
      footer_audio: [@audio_cta_alternate_path],
      qr_code_url: Map.get(@inaccessible_station_urls, station_id)
    }
  end

  defp station_has_no_elevators(_station_id, _all_elevators_at_station), do: nil

  # if reached: station has elevators
  defp closed_here_without_nearby_backups(closures, station_id, closed_ids) do
    closures_here =
      Enum.filter(closures, fn %Closure{facility: %Facility{stop: %Stop{id: id}}} ->
        id == station_id
      end)

    case {
      closures_here,
      Enum.filter(closures_here, &(not has_redundancy?(&1, [:nearby], closed_ids)))
    } do
      {_closures_here, []} ->
        nil

      {
        [
          %Closure{
            alert: %Alert{id: alert_id},
            elevator: elevator,
            facility: %Facility{long_name: name}
          }
        ],
        _
      } ->
        summary = if(is_nil(elevator), do: nil, else: elevator.summary)
        summary_line = ["#{name} is unavailable." | List.wrap(summary)]

        %Serialized{
          status: :alert,
          header: "An elevator is closed at this station.",
          footer_lines:
            footer_lines([
              summary_line,
              [
                if(summary, do: "For more info, go to ", else: "Find an alternate path on "),
                %{format: :bold, text: WebLink.stop_url_web(station_id)}
              ]
            ]),
          footer_audio:
            summary_line ++
              [if(summary, do: @audio_cta_full_list, else: @audio_cta_alternate_path)],
          qr_code_url: "https://#{WebLink.stop_alert_url_app(alert_id, station_id)}",
          alert_ids: [alert_id]
        }

      {closures_here, _} ->
        %Serialized{
          status: :alert,
          header: "Elevators are closed at this station.",
          callout_items:
            closures_here
            |> Enum.map(fn %Closure{facility: %Facility{long_name: name}} -> name end)
            |> Enum.sort(),
          footer_lines:
            footer_lines([
              [
                "Find an alternate path on ",
                %{format: :bold, text: WebLink.stop_url_web(station_id)}
              ]
            ]),
          footer_audio: [@audio_cta_alternate_path],
          qr_code_url: "https://#{WebLink.stop_url_app(station_id)}",
          alert_ids: Enum.map(closures_here, fn %Closure{alert: %Alert{id: id}} -> id end)
        }
    end
  end

  # if reached: no elevators (except with nearby redundancy) are closed at the home station
  defp closed_elsewhere_without_in_station_backups(closures, relevant_ids, closed_ids) do
    case closures
         |> Enum.group_by(fn %Closure{facility: %Facility{stop: stop}} -> stop end)
         |> Enum.split_with(fn {_stop, closures} ->
           Enum.all?(closures, &has_redundancy?(&1, [:nearby, :in_station], closed_ids))
         end) do
      {_with_in_station, _without_in_station = []} ->
        nil

      {with_in_station, without_in_station} ->
        {callout_stations, overflow} =
          without_in_station
          |> Enum.sort_by(fn {%Stop{id: id, name: name}, _closures} ->
            {if(id in relevant_ids, do: 0, else: 1), name}
          end)
          |> Enum.split(@max_callout_items)

        %Serialized{
          status: :alert,
          header:
            case callout_stations do
              [{station, [_closure]}] -> "Elevator closed at #{station_name(station)}"
              [{station, _closures}] -> "Elevators closed at #{station_name(station)}"
              _stations -> "Elevators closed at:"
            end,
          callout_items:
            case callout_stations do
              [_station] -> []
              stations -> Enum.map(stations, fn {station, _} -> station_name(station) end)
            end,
          footer_lines:
            footer_lines([
              Summary.text(
                with_in_station |> Enum.flat_map(&elem(&1, 1)) |> Enum.count(),
                overflow |> Enum.flat_map(&elem(&1, 1)) |> Enum.count(),
                @elevators_url
              )
            ]),
          footer_audio: [@audio_cta_full_list],
          qr_code_url: "https://#{@elevators_url}",
          alert_ids:
            without_in_station
            |> Enum.flat_map(&elem(&1, 1))
            |> Enum.map(fn %Closure{alert: %Alert{id: id}} -> id end)
        }
    end
  end

  # if reached: all closed elevators have in-station redundancy or better
  defp closed_elsewhere_with_in_station_backups(closures) do
    if Enum.any?(closures, fn %Closure{elevator: %Elevator{redundancy: redundancy}} ->
         redundancy == :in_station
       end) do
      %Serialized{
        status: :ok,
        header: "All elevators at this station are working.",
        footer_lines: footer_lines([Summary.text(Enum.count(closures), 0, @elevators_url)]),
        footer_audio: [@audio_cta_full_list],
        qr_code_url: "https://#{@elevators_url}"
      }
    end
  end

  # if reached: all closed elevators have nearby redundancy
  defp all_working_or_closed_with_nearby_backups(closures) do
    closures? = Enum.any?(closures)

    %Serialized{
      status: :ok,
      header: "All MBTA elevators are working#{if(not closures?, do: ".")}",
      header_size: :large,
      footer_lines:
        if(closures?,
          do: footer_lines([["or have a backup within 20 feet."]]),
          else: []
        ),
      cta_type: :app,
      qr_code_url: "https://#{@app_cta_url}"
    }
  end

  defp footer_lines(lines), do: Enum.map(lines, &%FreeTextLine{icon: nil, text: &1})

  # Only consider an elevator to "have" its stated redundancy category when all of its alternate
  # elevators are available.
  defp has_redundancy?(
         %Closure{elevator: %Elevator{alternate_ids: alternate_ids, redundancy: redundancy}},
         categories,
         closed_ids
       ) do
    redundancy in categories and alternate_ids |> MapSet.new() |> MapSet.disjoint?(closed_ids)
  end

  defp has_redundancy?(%Closure{elevator: nil}, _categories, _closed_ids), do: false

  defp station_name(%Stop{id: "place-masta"}), do: "Mass Ave"
  defp station_name(%Stop{name: name}), do: name

  defimpl Screens.V2.AlertsWidget do
    alias Screens.V2.WidgetInstance.ElevatorStatus

    # This is not an ideal approach since it ends up double-serializing the widget: once for the
    # actual serialization and once to determine which alert IDs are displayed. However, since
    # the logic that determines which closures appear in the widget is part of the serialization,
    # this is the simplest way to avoid duplication and guarantee alignment.
    def alert_ids(instance), do: ElevatorStatus.serialize(instance).alert_ids
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorStatus

    def priority(_instance), do: [2]
    def serialize(instance), do: ElevatorStatus.serialize_to_map(instance)
    def slot_names(_instance), do: [:lower_right]
    def page_groups(_instance), do: []
    def widget_type(_instance), do: :elevator_status
    def valid_candidate?(_instance), do: true
    def audio_serialize(instance), do: ElevatorStatus.serialize_to_map(instance)
    def audio_sort_key(_instance), do: [4]
    def audio_valid_candidate?(_instance), do: true
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorStatusView
  end
end
