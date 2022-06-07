defmodule Screens.Psa do
  @moduledoc false
  alias Screens.Config.{PsaConfig, Screen, Solari, State}

  @eink_refresh_seconds 30
  @solari_refresh_seconds 15
  @solari_psa_period 3

  @s3_base_url "https://mbta-screens.s3.amazonaws.com/"

  def current_psa_for(screen_id) do
    %Screen{
      app_id: app_id,
      app_params: %_app{psa_config: psa_config}
    } = State.screen(screen_id)

    %PsaConfig{
      default_list: default_list,
      scheduled_overrides: scheduled_overrides
    } = psa_config

    {psa_type, psa_list} = get_active_psa_list(scheduled_overrides, default_list)

    psa_s3_url =
      psa_list
      |> choose_psa(app_id, psa_type)
      |> get_s3_url()

    {psa_type, psa_s3_url}
  end

  def current_audio_psa_for(screen_id) do
    case State.app_params(screen_id) do
      %Solari{audio_psa: audio_psa} -> audio_psa
      _ -> nil
    end
  end

  defp get_active_psa_list(scheduled_overrides, default_list) do
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    now = DateTime.utc_now()

    Enum.find_value(scheduled_overrides, default_list, fn override ->
      if in_date_time_range?(now, {override.start_time, override.end_time}),
        do: override.psa_list,
        else: false
    end)
  end

  defp in_date_time_range?(_dt, {nil, nil}), do: true

  defp in_date_time_range?(dt, {start_time, nil}) do
    DateTime.compare(dt, start_time) in [:gt, :eq]
  end

  defp in_date_time_range?(dt, {nil, end_time}) do
    DateTime.compare(dt, end_time) == :lt
  end

  defp in_date_time_range?(dt, {start_time, end_time}) do
    in_date_time_range?(dt, {start_time, nil}) and in_date_time_range?(dt, {nil, end_time})
  end

  defp choose_psa(psa_list, :solari, :slide_in) do
    # How often to change the selected PSA
    solari_psa_refresh_seconds = @solari_refresh_seconds * @solari_psa_period

    # Choose which PSA to show, if we're showing one this refresh
    solari_psa = choose_from_rotating_list(psa_list, solari_psa_refresh_seconds)

    # Return either the current PSA or nil
    solari_list = [solari_psa] ++ List.duplicate(nil, @solari_psa_period - 1)
    choose_from_rotating_list(solari_list, @solari_refresh_seconds)
  end

  defp choose_psa(psa_list, :solari, _psa_type) do
    choose_from_rotating_list(psa_list, @solari_refresh_seconds)
  end

  defp choose_psa(psa_list, _app_id, _psa_type) do
    choose_from_rotating_list(psa_list, @eink_refresh_seconds)
  end

  defp choose_from_rotating_list([], _), do: nil
  defp choose_from_rotating_list([psa], _), do: psa

  defp choose_from_rotating_list(list, seconds_to_show) do
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    t = DateTime.utc_now()
    seconds_since_midnight = t.hour * 60 * 60 + t.minute * 60 + t.second
    periods_since_midnight = div(seconds_since_midnight, seconds_to_show)
    current_index = rem(periods_since_midnight, length(list))
    Enum.at(list, current_index)
  end

  defp get_s3_url(nil), do: nil
  defp get_s3_url(filename), do: @s3_base_url <> psa_images_prefix() <> filename

  defp psa_images_prefix do
    Application.get_env(:screens, :environment_name, "screens-prod") <> "/images/psa/"
  end
end
