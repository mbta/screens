defmodule Screens.V2.CandidateGenerator.BusEink do
  @moduledoc false

  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{BottomScreenFiller, FareInfoFooter, NormalHeader}
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{BusEink, Footer}
  alias ScreensConfig.V2.Header.CurrentStopId

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       screen_normal: [
         :header,
         {:body,
          %{
            body_normal: [
              :main_content,
              Builder.with_paging({:flex_zone, %{one_medium: [:medium]}}, 2),
              :footer
            ],
            body_takeover: [
              :full_body_top_screen,
              :full_body_bottom_screen
            ],
            bottom_takeover: [
              :main_content,
              :full_body_bottom_screen
            ],
            flex_zone_takeover: [
              :main_content,
              :flex_zone_takeover,
              :footer
            ]
          }}
       ],
       screen_takeover: [:full_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def candidate_instances(
        config,
        _opts,
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/1,
        alert_instances_fn \\ &Widgets.Alerts.alert_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1,
        subway_status_instances_fn \\ &Widgets.SubwayStatus.subway_status_instances/2
      ) do
    [
      fn -> header_instances(config, now, fetch_stop_name_fn) end,
      fn -> departures_instances_fn.(config) end,
      fn -> alert_instances_fn.(config) end,
      fn -> footer_instances(config) end,
      fn -> evergreen_content_instances_fn.(config) end,
      fn -> bottom_screen_filler_instances(config) end,
      fn -> subway_status_instances_fn.(config, now) end
    ]
    |> Task.async_stream(& &1.(), timeout: 30_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp header_instances(config, now, fetch_stop_name_fn) do
    %Screen{app_params: %BusEink{header: %CurrentStopId{stop_id: stop_id}}} = config

    case fetch_stop_name_fn.(stop_id) do
      nil -> []
      stop_name -> [%NormalHeader{screen: config, text: stop_name, time: now}]
    end
  end

  defp footer_instances(config) do
    %Screen{app_params: %BusEink{footer: %Footer{stop_id: stop_id}}} = config

    [
      %FareInfoFooter{
        screen: config,
        mode: :bus,
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/#{stop_id}"
      }
    ]
  end

  defp bottom_screen_filler_instances(config) do
    [%BottomScreenFiller{screen: config}]
  end
end
