defmodule Screens.V2.CandidateGenerator.BusShelter do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Predictions.Prediction
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget

  alias Screens.V2.WidgetInstance.{
    Departures,
    DeparturesNoData,
    NormalFooter,
    NormalHeader,
    StaticImage
  }

  @behaviour CandidateGenerator

  # Using Columbus Ave @ Walnut Ave until we have real config
  @dummy_stop_id "1743"
  @dummy_station_name "Columbus Ave @ Walnut Ave"

  @dummy_psa_priority [5]
  @dummy_psa_size :small

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [
         :header,
         :main_content,
         {:flex_zone,
          %{
            one_large: [:large],
            one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
            two_medium: [:medium_left, :medium_right]
          }},
         :footer
       ],
       takeover: [:fullscreen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(
        :ok = config,
        prediction_fetcher \\ &Prediction.fetch/1,
        alert_fetcher \\ &Alert.fetch/1
      ) do
    departures_widget =
      @dummy_stop_id
      |> fetch_predictions(prediction_fetcher)
      |> generate_departures_widget(config)

    alert_widgets =
      @dummy_stop_id
      |> fetch_alerts(alert_fetcher)
      |> generate_alert_widgets(config)

    psa_widgets =
      config
      |> fetch_psas()
      |> generate_static_image_widgets(config)

    header_widget = %NormalHeader{station_name: @dummy_station_name, time: DateTime.utc_now()}
    footer_widget = %NormalFooter{url: "mbta.com/stops/#{@dummy_stop_id}"}

    [departures_widget] ++ alert_widgets ++ psa_widgets ++ [header_widget] ++ [footer_widget]
  end

  defp fetch_predictions(stop_id, prediction_fetcher) do
    prediction_fetcher.(%{stop_ids: [stop_id]})
  end

  defp generate_departures_widget({:ok, predictions}, config) do
    %Departures{screen: config, predictions: predictions}
  end

  defp generate_departures_widget(:error, config) do
    %DeparturesNoData{screen: config}
  end

  defp fetch_alerts(stop_id, alert_fetcher) do
    alert_fetcher.(stop_ids: [stop_id])
  end

  defp generate_alert_widgets(alerts, config) do
    Enum.map(alerts, &%AlertWidget{screen: config, alert: &1})
  end

  defp fetch_psas(:ok) do
    [
      %{
        image_url:
          "https://mbta-screens.s3.amazonaws.com/screens-dev/images/psa/dummy-bus-shelter-psa-1.png",
        priority: @dummy_psa_priority,
        size: @dummy_psa_size
      },
      %{
        image_url:
          "https://mbta-screens.s3.amazonaws.com/screens-dev/images/psa/dummy-bus-shelter-psa-2.png",
        priority: @dummy_psa_priority,
        size: @dummy_psa_size
      }
    ]
  end

  defp generate_static_image_widgets(psas, config) do
    Enum.map(
      psas,
      &%StaticImage{screen: config, image_url: &1.image_url, priority: &1.priority, size: &1.size}
    )
  end
end
