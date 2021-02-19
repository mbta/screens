defmodule Screens.V2.ScreenData do
  @moduledoc false

  @type screen_id :: String.t()
  @type config :: :ok
  @type candidate_generator :: module()
  @type candidate_templates :: :ok
  @type candidate_instances :: :ok
  @type selected_template :: :ok
  @type selected_widgets :: :ok
  @type selected :: {selected_template, selected_widgets}
  @type serializable_map :: :ok

  @spec by_screen_id(screen_id()) :: serializable_map()
  def by_screen_id(screen_id) do
    config = get_config(screen_id)
    candidate_generator = get_candidate_generator(config)
    candidate_templates = candidate_generator.candidate_templates()
    candidate_instances = candidate_generator.candidate_instances(config)

    candidate_templates
    |> pick_instances(candidate_instances)
    |> serialize()
  end

  @spec get_config(screen_id()) :: config()
  def get_config(_screen_id) do
    :ok
  end

  @spec get_candidate_generator(config()) :: candidate_generator()
  def get_candidate_generator(:ok) do
    Screens.V2.CandidateGenerator.BusShelter
  end

  @spec pick_instances(candidate_templates(), candidate_instances()) :: selected()
  def pick_instances(:ok, :ok) do
    {:ok, :ok}
  end

  @spec serialize(selected()) :: serializable_map()
  def serialize({:ok, :ok}) do
    :ok
  end
end
