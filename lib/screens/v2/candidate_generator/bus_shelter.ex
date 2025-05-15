defmodule Screens.V2.CandidateGenerator.BusShelter do
  @moduledoc false

  alias Screens.Util.Assets
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.LinkFooter
  alias Screens.V2.WidgetInstance.Survey, as: SurveyInstance
  alias ScreensConfig.{Footer, Survey}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.BusShelter

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template(_screen) do
    {:screen,
     %{
       screen_normal: [
         :header,
         {:body,
          %{
            body_normal: [
              :main_content,
              Builder.with_paging(
                {:flex_zone,
                 %{
                   one_large: [:large],
                   one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
                   two_medium: [:medium_left, :medium_right]
                 }},
                3
              ),
              :footer
            ],
            body_takeover: [:full_body]
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
        now \\ DateTime.utc_now(),
        header_instances_fn \\ &Widgets.Header.instances/2,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/2,
        alert_instances_fn \\ &Widgets.Alerts.alert_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/2,
        subway_status_instances_fn \\ &Widgets.SubwayStatus.subway_status_instances/2
      ) do
    [
      fn -> header_instances_fn.(config, now) end,
      fn -> departures_instances_fn.(config, now) end,
      fn -> alert_instances_fn.(config, now) end,
      fn -> footer_instances(config) end,
      fn -> subway_status_instances_fn.(config, now) end,
      fn -> evergreen_content_instances_fn.(config, now) end,
      fn -> survey_instances(config) end
    ]
    |> Task.async_stream(& &1.(), timeout: 20_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp footer_instances(config) do
    %Screen{app_params: %BusShelter{footer: %Footer{stop_id: stop_id}}} = config
    [%LinkFooter{screen: config, text: "More at", url: "mbta.com/stops/#{stop_id}"}]
  end

  defp survey_instances(config) do
    %Screen{
      app_params: %BusShelter{
        survey: %Survey{
          enabled: enabled,
          medium_asset_path: medium_asset_path,
          large_asset_path: large_asset_path
        }
      }
    } = config

    [
      %SurveyInstance{
        screen: config,
        enabled?: enabled,
        medium_asset_url: Assets.s3_asset_url(medium_asset_path),
        large_asset_url: Assets.s3_asset_url(large_asset_path)
      }
    ]
  end
end
