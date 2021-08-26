defmodule Screens.V2.CandidateGenerator.BusShelter do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{BusShelter, EvergreenContentItem, Footer}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder

  alias Screens.V2.WidgetInstance.{
    EvergreenContent,
    LinkFooter,
    NormalHeader,
    SubwayStatus
  }

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
        fetch_stop_name_fn \\ &fetch_stop_name/1,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/1,
        alert_instances_fn \\ &Widgets.Alerts.alert_instances/1
      ) do
    [
      fn -> header_instances(config, now, fetch_stop_name_fn) end,
      fn -> departures_instances_fn.(config) end,
      fn -> alert_instances_fn.(config) end,
      fn -> footer_instances(config) end,
      fn -> subway_status_instances(config) end,
      fn -> evergreen_content_instances(config) end
    ]
    |> Task.async_stream(& &1.(), ordered: false)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  defp subway_status_instances(config) do
    route_ids = ["Blue", "Orange", "Red", "Green-B", "Green-C", "Green-D", "Green-E"]

    case Screens.Alerts.Alert.fetch(route_ids: route_ids) do
      {:ok, alerts} -> [%SubwayStatus{screen: config, subway_alerts: alerts}]
      :error -> []
    end
  end

  defp header_instances(config, now, fetch_stop_name_fn) do
    %Screen{app_params: %BusShelter{header: %CurrentStopId{stop_id: stop_id}}} = config

    case fetch_stop_name_fn.(stop_id) do
      nil -> []
      stop_name -> [%NormalHeader{screen: config, text: stop_name, time: now}]
    end
  end

  defp footer_instances(config) do
    %Screen{app_params: %BusShelter{footer: %Footer{stop_id: stop_id}}} = config
    [%LinkFooter{screen: config, text: "More at", url: "mbta.com/stops/#{stop_id}"}]
  end

  defp evergreen_content_instances(config) do
    %Screen{app_params: %BusShelter{evergreen_content: evergreen_content}} = config

    Enum.map(evergreen_content, &evergreen_content_instance(&1, config))
  end

  defp evergreen_content_instance(
         %EvergreenContentItem{
           slot_names: slot_names,
           asset_path: asset_path,
           priority: priority
         },
         config
       ) do
    %EvergreenContent{
      screen: config,
      slot_names: slot_names,
      asset_url: s3_asset_url(asset_path),
      priority: priority
    }
  end

  defp s3_asset_url(asset_path) do
    env = Application.get_env(:screens, :environment_name, "screens-prod")
    "https://mbta-screens.s3.amazonaws.com/#{env}/#{asset_path}"
  end

  defp fetch_stop_name(stop_id) do
    case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_id}) do
      {:ok, %{"data" => [stop_data]}} ->
        %{"attributes" => %{"name" => stop_name}} = stop_data
        stop_name

      _ ->
        nil
    end
  end
end
