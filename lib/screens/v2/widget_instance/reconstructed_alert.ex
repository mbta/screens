defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  defstruct screen: nil,
            alert: nil,
            now: nil,
            stop_sequences: nil,
            routes_at_stop: nil

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          now: DateTime.t(),
          stop_sequences: list(list(stop_id())),
          routes_at_stop: list(%{route_id: route_id(), active?: boolean()})
        }

  def serialize(%__MODULE__{alert: %Alert{header: header} = alert}) do
    %{
      # issue: FreeTextLine | String,
      issue: "No trains",
      # location: String,
      location: "Between Hynes Convention Center and Park St",
      # cause: String,
      cause: "Due to a medical emergency",
      # remedy: built frontend
      # routes: list(String),
      routes: ["Orange"],
      # urgent: boolean,
      urgent: false,
      # effect: atom
      effect: :shuttle
      
      # issue (no <TYPE> trains or station closed for takeover; reconstructed or full PIO alert for regular)
      # location range (optional)
      # cause
      # cta (optional; should this include icon + accessibility icon?)
      # routes (will inform card color and the pill)
      # style (urgent or not)
      # effect (informs icon and whether "delay" will display)
    }
  end

  def priority(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t), do: [1], else: [3]
  end

  def slot_names(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t), do: [:full_body], else: [:large]
  end

  def widget_type(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t), do: :reconstructed_takeover, else: :reconstructed_large_alert
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(t), do: ReconstructedAlert.priority(t)
    def serialize(t), do: ReconstructedAlert.serialize(t)
    def slot_names(t), do: ReconstructedAlert.slot_names(t)
    def widget_type(t), do: ReconstructedAlert.widget_type(t)
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: 0
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ReconstructedAlertView
  end
end
