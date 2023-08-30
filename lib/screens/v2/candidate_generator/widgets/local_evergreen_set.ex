defmodule Screens.V2.CandidateGenerator.Widgets.LocalEvergreenSet do
  @moduledoc """
  Widget for displaying evergreen content that is stored internally.
  Additionally, allows us to set a group of PSAs that appear in conjunction.
  Currently used only by Triptychs, which randomizes which PSA set appears.
  """

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias Screens.Config.V2.{LocalEvergreenSet, Triptych}
  alias Screens.Util.Assets

  def local_evergreen_set_instances(
        %Screen{app_params: %app{local_evergreen_set: local_evergreen_sets}} = config,
        now \\ DateTime.utc_now()
      )
      when app in [Triptych] do

    {seed_number, _} = now
    |> DateTime.truncate(:second)
    |> DateTime.to_gregorian_seconds()
    
    :rand.seed(:exsss, {seed_number, seed_number, seed_number})

    local_evergreen_sets
    |> Enum.random()
    |> get_set_instances(config, now)
  end

  defp get_set_instances(
         %LocalEvergreenSet{
           folder_name: folder_name,
           schedule: schedule
         },
        config,
        now
       ) do
    with  path = "assets/static/images/triptych_psas/" <> folder_name,
          {:ok, files} <- File.ls(path) do

      Enum.map(files, fn file ->
        slot_name = file
        |> String.replace_suffix(".png", "")
        |> String.to_atom()

        %EvergreenContent{
          screen: config,
          slot_names: [slot_name],
          asset_url: path <> "/" <> file,
          priority: [2],
          schedule: schedule,
          now: now,
          text_for_audio: "",
          audio_priority: [0]
        }
      end)

    else
      :error -> []
    end
  end
end
