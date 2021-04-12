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
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &fetch_stop_name/1
      ) do
    header_instances(config, now, fetch_stop_name_fn) ++
      [
        %Placeholder{color: :blue, slot_names: [:footer]},
        %Placeholder{color: :red, slot_names: [:main_content]},
        %Placeholder{color: :green, slot_names: [:medium_left]},
        %Placeholder{color: :blue, slot_names: [:small_upper_right]},
        %Placeholder{color: :grey, slot_names: [:small_lower_right]}
      ]
  end

  defp header_instances(config, now, fetch_stop_name_fn) do
    %Screen{app_params: %BusShelter{stop_id: stop_id}} = config

    case fetch_stop_name_fn.(stop_id) do
      nil -> []
      stop_name -> [%NormalHeader{screen: config, text: stop_name, time: now}]
    end
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
