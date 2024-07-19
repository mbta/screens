defmodule Screens.V2.WidgetInstance.EvergreenContent do
  @moduledoc false

  alias Screens.Util
  alias Screens.V2.WidgetInstance
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{RecurrentSchedule, Schedule, Triptych}

  @enforce_keys ~w[screen slot_names asset_url priority now]a
  defstruct screen: nil,
            slot_names: nil,
            asset_url: nil,
            priority: nil,
            schedule: [%Schedule{}],
            now: nil,
            text_for_audio: nil,
            audio_priority: nil,
            show_identifiers: false

  @type t :: %__MODULE__{
          screen: Screen.t(),
          slot_names: list(WidgetInstance.slot_id()),
          asset_url: String.t(),
          priority: WidgetInstance.priority(),
          schedule: list(Schedule.t()) | RecurrentSchedule.t(),
          now: DateTime.t(),
          text_for_audio: String.t(),
          audio_priority: WidgetInstance.priority(),
          show_identifiers: boolean()
        }

  def priority(%__MODULE__{} = instance), do: instance.priority

  def serialize(%__MODULE__{
        screen: %Screen{app_params: %Triptych{show_identifiers: show_identifiers}},
        asset_url: asset_url
      }),
      do: %{asset_url: asset_url, show_identifiers: show_identifiers}

  def serialize(%__MODULE__{asset_url: asset_url}), do: %{asset_url: asset_url}

  def slot_names(%__MODULE__{slot_names: slot_names}), do: slot_names

  def widget_type(_instance), do: :evergreen_content

  def valid_candidate?(%__MODULE__{schedule: schedule, now: now}) when is_list(schedule) do
    # Valid if any of the schedule items contains `now`.

    schedule
    |> Enum.any?(fn
      %Schedule{start_dt: nil, end_dt: nil} ->
        true

      %Schedule{start_dt: start_dt, end_dt: nil} ->
        DateTime.compare(start_dt, now) in [:lt, :eq]

      %Schedule{start_dt: nil, end_dt: end_dt} ->
        DateTime.compare(end_dt, now) == :gt

      %Schedule{start_dt: start_dt, end_dt: end_dt} ->
        DateTime.compare(start_dt, now) in [:lt, :eq] and DateTime.compare(end_dt, now) == :gt
    end)
  end

  # Widget is valid if:
  # 1. now is within at least one of the schedule's time ranges, AND
  # 2. now is within at least one of the schedule's date ranges.
  #
  # Details
  # -------
  # Time ranges are checked inclusive of start_time_utc, exclusive of end_time_utc.
  # Date ranges are checked inclusive of both start and end.
  #
  # Time ranges are allowed to cross midnight. This is detected by checking if start time is after end time.
  # If a time range crosses midnight, it's treated as crossing from today to tomorrow, *not* yesterday to today.
  def valid_candidate?(%__MODULE__{schedule: schedule, now: now}) do
    time_match =
      Enum.find(schedule.times, &Util.time_in_range?(now, &1.start_time_utc, &1.end_time_utc))

    if is_nil(time_match) do
      false
    else
      time_match_crosses_utc_midnight =
        Time.compare(time_match.start_time_utc, time_match.end_time_utc) == :gt

      if time_match_crosses_utc_midnight do
        time_in_overnight_range?(now, time_match, schedule.dates)
      else
        Enum.any?(
          schedule.dates,
          &(Date.compare(now, &1.start_date) in [:gt, :eq] and
              Date.compare(now, &1.end_date) in [:lt, :eq])
        )
      end
    end
  end

  # Checks if `now` is within the given `time_range` that crosses UTC midnight, as well as at least one of the date ranges in `dates`.
  #
  # If `now` is within the part of the time period that's past midnight, we shift all date ranges forward by one day to account for this.
  #
  # For example, if the time range is 22:00 - 03:00 and there's a date range that ends on 1/10,
  # then we still consider this to be a match if `now` is between 00:00 and 03:00 on 1/11 since that's just past midnight of 1/10.
  #
  # Conversely: with the same time range, and the date range starts on 1/5,
  # then it's *not* a match if `now` is between 00:00 and 03:00 on 1/5, because that's just past midnight of 1/4.
  defp time_in_overnight_range?(now, time_range, dates) do
    # True if `now` is in the part of `time_range` that is past midnight.
    now_is_past_midnight = Util.time_in_range?(now, ~T[00:00:00], time_range.end_time_utc)

    dates =
      if now_is_past_midnight do
        shift_dates_for_past_midnight(dates)
      else
        dates
      end

    Enum.any?(
      dates,
      &(Date.compare(now, &1.start_date) in [:gt, :eq] and
          Date.compare(now, &1.end_date) in [:lt, :eq])
    )
  end

  defp shift_dates_for_past_midnight(dates) do
    Enum.map(dates, fn date_range ->
      Map.new(date_range, fn {k, date} -> {k, Date.add(date, 1)} end)
    end)
  end

  def audio_serialize(%__MODULE__{text_for_audio: text_for_audio}),
    do: %{text_for_audio: text_for_audio}

  def audio_sort_key(%__MODULE__{} = instance), do: instance.audio_priority

  def audio_valid_candidate?(%__MODULE__{text_for_audio: text_for_audio})
      when not is_nil(text_for_audio),
      do: true

  def audio_valid_candidate?(_), do: false

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.EvergreenContent

    def priority(instance), do: EvergreenContent.priority(instance)
    def serialize(instance), do: EvergreenContent.serialize(instance)
    def slot_names(instance), do: EvergreenContent.slot_names(instance)
    def widget_type(instance), do: EvergreenContent.widget_type(instance)
    def valid_candidate?(instance), do: EvergreenContent.valid_candidate?(instance)
    def audio_serialize(instance), do: EvergreenContent.audio_serialize(instance)
    def audio_sort_key(instance), do: EvergreenContent.audio_sort_key(instance)

    def audio_valid_candidate?(instance),
      do: EvergreenContent.audio_valid_candidate?(instance)

    def audio_view(_instance), do: ScreensWeb.V2.Audio.EvergreenContentView
  end
end
