defmodule Screens.V2.WidgetInstance.DupSpecialCaseAlert do
  @moduledoc """
  A mostly logic-less widget that displays a "special case" alert on a DUP screen.

  This widget should always serialize the same as the DupAlert widget:
  Its serialized data must be valid for a DUP full-screen or partial alert on the client.
  """

  alias ScreensConfig.V2.FreeText
  alias Screens.V2.WidgetInstance

  @enforce_keys [:alert_ids, :slot_names, :widget_type, :special_case]
  defstruct @enforce_keys ++ [:branches]

  @type t :: %__MODULE__{
          # IDs of alert(s) represented by this widget, so that we can properly report
          # to ScreensByAlert
          alert_ids: list(alert_id),
          slot_names: list(WidgetInstance.slot_id()),
          widget_type: WidgetInstance.widget_type(),
          branches: list(String.t()),
          special_case: special_case
        }

  @type alert_id :: String.t()
  @type special_case :: :kenmore_westbound_shuttles | :wtc_detour

  @spec serialize(t()) :: map()
  def serialize(t) do
    case t do
      %{special_case: :kenmore_westbound_shuttles, widget_type: :partial_alert} ->
        %{
          text: %ScreensConfig.V2.FreeTextLine{
            icon: :warning,
            text: get_kenmore_special_text(t.branches, :partial_alert)
          },
          color: :green
        }

      %{special_case: :kenmore_westbound_shuttles, widget_type: :takeover_alert} ->
        %{
          text: %ScreensConfig.V2.FreeTextLine{
            icon: :warning,
            text: get_kenmore_special_text(t.branches, :takeover_alert)
          },
          header: %{color: :green, text: "Kenmore"},
          remedy: %ScreensConfig.V2.FreeTextLine{
            icon: :shuttle,
            text: [%{format: :bold, text: "Use shuttle bus"}]
          }
        }

      %{special_case: :wtc_detour} ->
        %{
          text: %ScreensConfig.V2.FreeTextLine{
            icon: :warning,
            text: ["Building closed"]
          },
          header: %{color: :silver, text: "World Trade Ctr"},
          remedy: %ScreensConfig.V2.FreeTextLine{
            icon: :shuttle,
            text: [%{format: :bold, text: "Board Silver Line on street"}]
          }
        }

      _ ->
        %{}
    end
  end

  @spec get_kenmore_special_text(list(String.t()), atom()) :: list(FreeText.t())
  def get_kenmore_special_text(["b", "c"], :partial_alert),
    do: ["No", %{format: :bold, text: "Bost Coll/Clvlnd Cir"}]

  def get_kenmore_special_text(["b", "c"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_b"},
      %{format: :bold, text: "Bost Coll"},
      "or",
      %{icon: "green_c"},
      %{format: :bold, text: "Cleveland Cir"},
      "trains"
    ]

  def get_kenmore_special_text(["b", "d"], :partial_alert),
    do: ["No", %{format: :bold, text: "Bost Coll / Riverside"}]

  def get_kenmore_special_text(["b", "d"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_b"},
      %{format: :bold, text: "Boston College"},
      "or",
      %{icon: "green_d"},
      %{format: :bold, text: "Riverside"},
      "trains"
    ]

  def get_kenmore_special_text(["c", "d"], :partial_alert),
    do: ["No", %{format: :bold, text: "Clvlnd Cir/Riverside"}]

  def get_kenmore_special_text(["c", "d"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_c"},
      %{format: :bold, text: "Cleveland Cir"},
      "or",
      %{icon: "green_d"},
      %{format: :bold, text: "Riverside"},
      "trains"
    ]

  def get_kenmore_special_text(["b", "c", "d"], :partial_alert),
    do: ["No", %{format: :bold, text: "Westbound"}, "trains"]

  def get_kenmore_special_text(["b", "c", "d"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_b"},
      %{icon: "green_c"},
      %{icon: "green_d"},
      %{special: "break"},
      %{format: :bold, text: "Westbound"},
      "trains"
    ]

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DupSpecialCaseAlert

    def priority(_t), do: [1, 2]
    def serialize(t), do: DupSpecialCaseAlert.serialize(t)
    def slot_names(t), do: t.slot_names
    def widget_type(t), do: t.widget_type
    def valid_candidate?(_t), do: true
    def audio_serialize(_t), do: %{}
    def audio_sort_key(_t), do: [0]
    def audio_valid_candidate?(_t), do: false
    def audio_view(_t), do: nil
  end

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(instance), do: instance.alert_ids
  end
end
