defmodule Screens.V2.WidgetInstance.EvergreenContent do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Schedule
  alias Screens.V2.WidgetInstance

  @enforce_keys ~w[screen slot_names asset_url priority now]a
  defstruct screen: nil,
            slot_names: nil,
            asset_url: nil,
            priority: nil,
            schedule: [%Schedule{}],
            now: nil,
            text_for_audio: nil,
            audio_priority: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          slot_names: list(WidgetInstance.slot_id()),
          asset_url: String.t(),
          priority: WidgetInstance.priority(),
          schedule: list(Schedule.t()),
          now: DateTime.t(),
          text_for_audio: String.t(),
          audio_priority: WidgetInstance.priority()
        }

  def priority(%__MODULE__{} = instance), do: instance.priority

  def serialize(%__MODULE__{asset_url: asset_url}), do: %{asset_url: asset_url}

  def slot_names(%__MODULE__{slot_names: slot_names}), do: slot_names

  def widget_type(_instance), do: :evergreen_content

  def valid_candidate?(%__MODULE__{schedule: schedule, now: now}) do
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
