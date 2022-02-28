defmodule Screens.V2.CandidateGenerator.BusEink do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{BusEink, Footer}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{BottomScreenFiller, FareInfoFooter, NormalHeader}

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
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &fetch_stop_name/1,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/1,
        alert_instances_fn \\ &Widgets.Alerts.alert_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1
      ) do
    [
      fn -> header_instances(config, now, fetch_stop_name_fn) end,
      fn -> departures_instances_fn.(config) end,
      fn -> alert_instances_fn.(config) end,
      fn -> footer_instances(config) end,
      fn -> evergreen_content_instances_fn.(config) end,
      fn -> bottom_screen_filler_instances(config) end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

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

  # this can be a utility.  See bus_shelter.ex line 112
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
