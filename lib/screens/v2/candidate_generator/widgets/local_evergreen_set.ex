defmodule Screens.V2.CandidateGenerator.Widgets.LocalEvergreenSet do
  @moduledoc """
  Widget for displaying evergreen content that is stored internally.
  Additionally, allows us to set a group of PSAs that appear in conjunction.
  Currently used only by Triptychs, which randomizes which PSA set appears.
  """

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias Screens.Config.V2.{LocalEvergreenSet, Triptych}

  def local_evergreen_set_instances(
        %Screen{app_params: %app{local_evergreen_sets: local_evergreen_sets}} = config,
        now \\ DateTime.utc_now()
      )
      when app in [Triptych] do
    # Use the current time to help seed the random number generator so that all 3 screens
    # should be in sync. So we'll seed with current time rounded down to the nearest multiple of 15 seconds.
    # (Known risk: it's remotely possible that the screens are panels are out-of-sync on either side of a 15-second boundary)
    seed_number =
      now
      |> DateTime.truncate(:second)
      |> DateTime.to_gregorian_seconds()
      |> elem(0)
      |> Kernel./(15)
      |> floor()

    :rand.seed(:exsss, {seed_number, seed_number, seed_number})

    local_evergreen_sets
    |> Enum.random()
    |> get_set_instances(config, now)
  end

  def string_to_slot_name(string) do
    cond do
      String.contains?(string, "left") -> :left_pane
      String.contains?(string, "middle") -> :middle_pane
      String.contains?(string, "right") -> :right_pane
    end
  end

  defp get_set_instances(
         %LocalEvergreenSet{
           folder_name: folder_name,
           schedule: schedule
         },
         config,
         now
       ) do
    path = "assets/static/images/triptych_psas/" <> folder_name

    case File.ls(path) do
      {:ok, files} ->
        Enum.map(files, fn file ->
          slot_name =
            file
            |> String.replace_suffix(".png", "")
            |> string_to_slot_name()

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

      :error ->
        []
    end
  end
end
