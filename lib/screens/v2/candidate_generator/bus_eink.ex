defmodule Screens.V2.CandidateGenerator.BusEink do
  @moduledoc false

  alias Screens.Config.{Bus, Screen}
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}

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
  def candidate_instances(config) do
    header_instances(config) ++
      [
        %Placeholder{color: :blue, slot_names: [:footer]},
        %Placeholder{color: :green, slot_names: [:main_content]},
        %Placeholder{color: :red, slot_names: [:medium_flex]}
      ]
  end

  defp header_instances(config) do
    %Screen{app_params: %Bus{stop_id: stop_id}} = config

    case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_id}) do
      {:ok, %{"data" => [stop_data]}} ->
        %{"attributes" => %{"name" => stop_name}} = stop_data
        [%NormalHeader{screen: config, text: stop_name, time: DateTime.utc_now()}]

      _ ->
        []
    end
  end
end
