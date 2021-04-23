defmodule Screens.V2.CandidateGenerator.BusEink do
  @moduledoc false

  alias Screens.Config.{Bus, Screen}
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.{FareInfoFooter, NormalHeader, Placeholder}

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [
         :header,
         :main_content,
         :medium_flex,
         :footer
       ],
       bottom_takeover: [
         :header,
         :main_content,
         :bottom_screen
       ],
       full_takeover: [:full_screen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &fetch_stop_name/1
      ) do
    header_instances(config, now, fetch_stop_name_fn) ++
      footer_instances(config) ++
      [
        %Placeholder{color: :green, slot_names: [:main_content]},
        %Placeholder{color: :red, slot_names: [:medium_flex]}
      ]
  end

  defp header_instances(config, now, fetch_stop_name_fn) do
    %Screen{app_params: %Bus{stop_id: stop_id}} = config

    case fetch_stop_name_fn.(stop_id) do
      nil -> []
      stop_name -> [%NormalHeader{screen: config, text: stop_name, time: now}]
    end
  end

  defp footer_instances(%Screen{app_params: %Bus{stop_id: stop_id}} = config) do
    [
      %FareInfoFooter{
        screen: config,
        mode: :bus,
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/#{stop_id}"
      }
    ]
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
