defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  # Temporarily using subway alert type
  alias Screens.Alerts.Alert
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  defstruct alert: nil

  @type t :: %__MODULE__{
          alert: Alert.t()
        }

  def serialize(%__MODULE__{alert: %Alert{header: header}}) do
    %{alert_header: header}
  end

  # Priority will either be 3 if it's a regular alert
  #     or 1 if a takeover

  # slot_names will be :large if it's a regular alert
  #     or :full_body if a takeover

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]
    def serialize(t), do: ReconstructedAlert.serialize(t)
    def slot_names(_instance), do: [:large]
    def widget_type(_instance), do: :reconstructed_alert
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: 0
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ReconstructedAlertView
  end
end
