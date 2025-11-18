defmodule Screens.V2.WidgetInstance.ElevatorStatusNew do
  @moduledoc false

  alias Screens.Elevator
  alias Screens.Elevator.Closure
  alias Screens.Facilities.Facility
  alias Screens.Stops.Stop
  alias ScreensConfig.FreeTextLine

  @enforce_keys ~w[closures home_station_id]a
  defstruct @enforce_keys ++ [relevant_station_ids: []]

  @type t :: %__MODULE__{
          closures: [Closure.t()],
          home_station_id: Stop.id(),
          relevant_station_ids: MapSet.t(Stop.id())
        }

  defmodule Serialized do
    @moduledoc false

    @derive Jason.Encoder

    @type t :: %__MODULE__{
            status: :ok | :alert,
            header: String.t(),
            header_size: :large | :medium,
            callout_items: [String.t()],
            footer_lines: [FreeTextLine.t()],
            cta_type: :app | :plain,
            qr_code_url: String.t()
          }

    @enforce_keys ~w[status header qr_code_url]a
    defstruct @enforce_keys ++
                [header_size: :medium, callout_items: [], footer_lines: [], cta_type: :plain]
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
  @stop_url_base "mbta.com/stops"
  @max_callout_items 4

  @spec serialize(t()) :: Serialized.t()
  def serialize(%__MODULE__{
        closures: closures,
        home_station_id: home_station_id,
        relevant_station_ids: relevant_station_ids
      }) do
    closed_elevator_ids = MapSet.new(closures, fn %Closure{facility: %Facility{id: id}} -> id end)

    # Choose the first "scenario" that applies (ordered highest-priority first). Each function
    # returns a `Serialized` if it does apply or `nil` if it does not.
    Enum.find_value(
      [
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

  def serialize_to_map(%__MODULE__{} = widget), do: widget |> serialize() |> Map.from_struct()

  defp closed_here_without_nearby_backups(closures, station_id, closed_ids) do
    case Enum.filter(
           closures,
           &(at_station?(&1, station_id) and not has_redundancy?(&1, [:nearby], closed_ids))
         ) do
      [] ->
        nil

      [%Closure{elevator: elevator, facility: %Facility{long_name: name}}] ->
        summary = if(is_nil(elevator), do: nil, else: elevator.summary)

        %Serialized{
          status: :alert,
          header: "An elevator is closed at this station.",
          footer_lines:
            footer_lines([
              ["#{name} is unavailable." | List.wrap(summary)],
              [
                if(summary, do: "For more info, go to ", else: "Find an alternate path on "),
                %{format: :bold, text: stop_url(station_id)}
              ]
            ]),
          qr_code_url: "https://#{stop_url(station_id)}"
        }

      relevant_closures ->
        %Serialized{
          status: :alert,
          header: "Elevators are closed at this station.",
          callout_items:
            Enum.map(
              relevant_closures,
              fn %Closure{facility: %Facility{long_name: name}} -> name end
            ),
          footer_lines:
            footer_lines([
              ["Find an alternate path on ", %{format: :bold, text: stop_url(station_id)}]
            ]),
          qr_code_url: "https://#{stop_url(station_id)}"
        }
    end
  end

  # if reached: no elevators are closed at the home station
  defp closed_elsewhere_without_in_station_backups(closures, relevant_ids, closed_ids) do
    case Enum.split_with(closures, &has_redundancy?(&1, [:nearby, :in_station], closed_ids)) do
      {_with_in_station, _without_in_station = []} ->
        nil

      {with_in_station, without_in_station} ->
        {stations, overflow} =
          without_in_station
          |> Enum.group_by(fn %Closure{facility: %Facility{stop: stop}} -> stop end)
          |> Enum.sort_by(fn {%Stop{id: id, name: name}, _closures} ->
            {if(id in relevant_ids, do: 0, else: 1), name}
          end)
          |> Enum.split(@max_callout_items)

        %Serialized{
          status: :alert,
          header:
            case stations do
              [{station, [_closure]}] -> "Elevator closed at #{station_name(station)}"
              [{station, _closures}] -> "Elevators closed at #{station_name(station)}"
              _stations -> "Elevators closed at:"
            end,
          callout_items:
            case stations do
              [_station] -> []
              stations -> Enum.map(stations, fn {station, _} -> station_name(station) end)
            end,
          footer_lines:
            footer_lines([
              Summary.text(
                Enum.count(with_in_station),
                overflow |> Enum.flat_map(&elem(&1, 1)) |> Enum.count(),
                @elevators_url
              )
            ]),
          qr_code_url: "https://#{@elevators_url}"
        }
    end
  end

  # if reached: all closed elevators have in-station redundancy
  defp closed_elsewhere_with_in_station_backups(closures) do
    if Enum.any?(closures, fn %Closure{elevator: %Elevator{redundancy: redundancy}} ->
         redundancy == :in_station
       end) do
      %Serialized{
        status: :ok,
        header: "All elevators at this station are working.",
        footer_lines: footer_lines([Summary.text(Enum.count(closures), 0, @elevators_url)]),
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

  defp at_station?(%Closure{facility: %Facility{stop: %Stop{id: id}}}, id), do: true
  defp at_station?(_closure, _id), do: false

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

  defp stop_url(station_id), do: "#{@stop_url_base}/#{station_id}"

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(_instance), do: []
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorStatusNew

    def priority(_instance), do: [2]
    def serialize(instance), do: ElevatorStatusNew.serialize_to_map(instance)
    def slot_names(_instance), do: [:lower_right]
    def widget_type(_instance), do: :elevator_status_new
    def valid_candidate?(_instance), do: true
    def audio_serialize(instance), do: ElevatorStatusNew.serialize_to_map(instance)
    def audio_sort_key(_instance), do: [4]
    def audio_valid_candidate?(_instance), do: true
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorStatusNewView
  end
end
