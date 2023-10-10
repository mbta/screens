defmodule Screens.V2.CandidateGenerator.Widgets.LocalEvergreenSet do
  @moduledoc """
  Widget for displaying evergreen content that is stored internally.
  Additionally, allows us to set a group of PSAs that appear in conjunction.
  Currently used only by Triptychs, which randomizes which PSA set appears.
  """

  require Logger

  alias ScreensConfig.Screen
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias ScreensConfig.V2.{LocalEvergreenSet, Triptych}

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
      |> DateTime.to_unix()
      |> div(15)

    _ = :rand.seed(:exsss, {seed_number, seed_number, seed_number})

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
    relative_path = Path.join("triptych_psas/", folder_name)
    path = Path.join("assets/static/images/", relative_path)

    case File.ls(path) do
      {:ok, files} ->
        build_widget_instances(files, config, relative_path, schedule, now)

      {:error, _} ->
        relative_path = "triptych_psas/"
        path = Path.join("assets/static/images/", relative_path)

        case File.ls(path) do
          {:ok, triptych_psa_contents} ->
            default_psa_folder = hd(triptych_psa_contents)
            default_psa_path = Path.join(path, default_psa_folder)

            Logger.warn(
              "[Triptych PSA filepath not found, using default] configured_folder_name=#{folder_name} default_folder_name=#{default_psa_folder}"
            )

            files = File.ls!(default_psa_path)

            build_widget_instances(
              files,
              config,
              Path.join(relative_path, default_psa_folder),
              schedule,
              now
            )

          {:error, _} ->
            Logger.warn("[Empty triptych PSA folder]")
            []
        end
    end
  end

  defp build_widget_instances(files, config, partial_path, schedule, now) do
    Enum.map(files, fn file ->
      slot_name = string_to_slot_name(file)

      %EvergreenContent{
        screen: config,
        slot_names: [slot_name],
        asset_url: Path.join([partial_path, "/", file]),
        priority: [2],
        schedule: schedule,
        now: now,
        text_for_audio: "",
        audio_priority: [0]
      }
    end)
  end
end
