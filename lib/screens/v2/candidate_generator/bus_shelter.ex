defmodule Screens.V2.CandidateGenerator.BusShelter do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{BusShelter, Footer}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Helpers
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{LinkFooter, NormalHeader, Placeholder}

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [
         :header,
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
       takeover: [:full_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &fetch_stop_name/1,
        departures_instances_fn \\ &Helpers.Departures.departures_instances/1,
        alert_instances_fn \\ &Helpers.Alerts.alert_instances/1
      ) do
    [
      fn -> header_instances(config, now, fetch_stop_name_fn) end,
      fn -> departures_instances_fn.(config) end,
      fn -> alert_instances_fn.(config) end,
      fn -> footer_instances(config) end,
      fn -> placeholder_instances() end
    ]
    |> Task.async_stream(& &1.(), ordered: false)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
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

  defp fetch_stop_name(stop_id) do
    case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_id}) do
      {:ok, %{"data" => [stop_data]}} ->
        %{"attributes" => %{"name" => stop_name}} = stop_data
        stop_name

      _ ->
        nil
    end
  end

  defp placeholder_instances do
    [
      %Placeholder{color: :red, slot_names: [:main_content]},
      %Placeholder{color: :green, slot_names: [:medium_left]},
      %Placeholder{color: :blue, slot_names: [:small_upper_right]},
      %Placeholder{color: :grey, slot_names: [:small_lower_right]},
      %Placeholder{color: :green, slot_names: [:large]},
      %Placeholder{color: :red, slot_names: [:large]}
    ]
  end
end
