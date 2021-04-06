defmodule Screens.V2.CandidateGenerator.BusShelter do
  @moduledoc false

  alias Screens.Config.{BusShelter, Screen}
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
         {:flex_zone,
          %{
            one_large: [:large],
            one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
            two_medium: [:medium_left, :medium_right]
          }},
         :footer
       ],
       takeover: [:full_screen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(config) do
    header_instances(config) ++
      [
        %Placeholder{color: :blue, slot_names: [:footer]},
        %Placeholder{color: :red, slot_names: [:main_content]},
        %Placeholder{color: :green, slot_names: [:medium_left]},
        %Placeholder{color: :blue, slot_names: [:small_upper_right]},
        %Placeholder{color: :grey, slot_names: [:small_lower_right]}
      ]
  end

  defp header_instances(config) do
    %Screen{app_params: %BusShelter{stop_id: stop_id}} = config

    case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_id}) do
      {:ok, %{"data" => [stop_data]}} ->
        %{"attributes" => %{"name" => stop_name}} = stop_data
        [%NormalHeader{screen: config, text: stop_name, time: DateTime.utc_now()}]

      _ ->
        []
    end
  end
end
