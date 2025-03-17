defmodule Screens.V2.WidgetInstance.ElevatorClosures do
  @moduledoc "The main content of an elevator screen when its associated elevator is working."

  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.WidgetInstance.Elevator.Closure
  alias ScreensConfig.V2.Elevator

  defmodule Station do
    @moduledoc "A station where one or more elevators are currently closed."

    alias Screens.Routes.Route
    alias Screens.V2.WidgetInstance.Elevator.Closure

    @derive Jason.Encoder

    defstruct ~w[id name route_icons closures summary]a

    @type t :: %__MODULE__{
            id: Stop.id(),
            name: String.t(),
            route_icons: list(Route.icon()),
            closures: list(Closure.t()) | :no_closures,
            summary: String.t() | nil
          }
  end

  defmodule Upcoming do
    @moduledoc "An upcoming closure of a screen's associated elevator."

    @enforce_keys ~w[period]a
    defstruct @enforce_keys ++ ~w[summary]a

    @type t :: %__MODULE__{period: {Date.t(), Date.t() | nil}, summary: String.t() | nil}

    @nbsp "\u00A0"

    @spec serialize(t(), DateTime.t()) :: map()
    def serialize(%__MODULE__{period: {start_date, end_date}, summary: summary}, now) do
      today = Util.service_date(now)

      {banner_title, details_titles} = titles(today, start_date)
      {banner_postfix, details_postfix} = postfixes(today, start_date, end_date)

      %{
        banner: %{title: banner_title, postfix: banner_postfix},
        details: %{summary: summary, titles: details_titles, postfix: details_postfix}
      }
    end

    defp titles(today, start_date) do
      cond do
        next_day?(today, start_date) ->
          both_titles("Tomorrow")

        same_week?(today, start_date) ->
          both_titles("This #{day_name(start_date)}")

        true ->
          {
            "#{day_name(start_date)}, #{short(start_date)}",
            [
              "#{day_name(start_date)}, #{long(start_date)}",
              "#{day_name(start_date)}, #{short(start_date, _dot = true)}"
            ]
          }
      end
    end

    defp postfixes(today, start_date, end_date) do
      indefinite? = is_nil(end_date)
      relative_start? = next_day?(today, start_date) or same_week?(today, start_date)
      single_day? = start_date == end_date

      same_month? =
        not indefinite? and {start_date.year, start_date.month} == {end_date.year, end_date.month}

      cond do
        indefinite? ->
          both_postfixes("until further notice")

        single_day? ->
          if relative_start?, do: {short(start_date), long(start_date)}, else: both_postfixes(nil)

        true ->
          banner =
            if same_month?,
              do: "#{short(start_date)} – #{end_date.day}",
              else: "#{short(start_date)} – #{short(end_date)}"

          details =
            if relative_start?,
              do:
                if(same_month?,
                  do: "#{long(start_date)} – #{end_date.day}",
                  else: "#{long(start_date)} – #{long(end_date)}"
                ),
              else: "through #{long(end_date)}"

          {banner, details}
      end
    end

    defp next_day?(d1, d2), do: Date.diff(d1, d2) == -1
    defp same_week?(d1, d2), do: Date.beginning_of_week(d1) == Date.beginning_of_week(d2)

    defp both_postfixes(value), do: {value, value}
    defp both_titles(value), do: {value, [value]}
    defp day_name(date), do: Calendar.strftime(date, "%A")
    defp long(date), do: Calendar.strftime(date, "%B#{@nbsp}%-d")
    defp short(date, dot \\ false)
    defp short(date, false), do: Calendar.strftime(date, "%b#{@nbsp}%-d")
    defp short(date, true), do: Calendar.strftime(date, "%b.#{@nbsp}%-d")
  end

  @enforce_keys ~w[app_params now stations_with_closures station_id]a
  defstruct @enforce_keys ++ ~w[upcoming_closure]a

  @type t :: %__MODULE__{
          app_params: Elevator.t(),
          now: DateTime.t(),
          stations_with_closures: list(Station.t()) | :no_closures,
          station_id: String.t(),
          upcoming_closure: Upcoming.t() | nil
        }

  def serialize(%__MODULE__{
        app_params: %Elevator{elevator_id: id},
        now: now,
        stations_with_closures: stations_with_closures,
        station_id: station_id,
        upcoming_closure: upcoming_closure
      }),
      do: %{
        id: id,
        stations_with_closures: stations_with_closures,
        station_id: station_id,
        upcoming_closure: if(upcoming_closure, do: Upcoming.serialize(upcoming_closure, now))
      }

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorClosures

    def priority(_instance), do: [1]
    def serialize(instance), do: ElevatorClosures.serialize(instance)
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :elevator_closures
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorClosuresView
  end
end
