defmodule Screens.Psa do
  @moduledoc false
  alias Screens.Config.{PsaConfig, Screen, Solari, State}
  alias Screens.Config.PsaConfig.OverrideList

  @eink_refresh_seconds 30
  @solari_refresh_seconds 15
  @solari_psa_period 3

  def current_psa_for(screen_id) do
    %Screen{
      app_id: app_id,
      app_params: %_app{psa_config: psa_config}
    } = State.screen(screen_id)

    %PsaConfig{
      default_list: default_list,
      override_list: %OverrideList{psa_list: override_list, active_time_range: active_time_range}
    } = psa_config

    {psa_type, psa_list} = get_active_psa_list(active_time_range, default_list, override_list)

    {psa_type, choose_psa(psa_list, app_id)}
  end

  def current_audio_psa_for(screen_id) do
    case State.app_params(screen_id) do
      %Solari{audio_psa: audio_psa} -> audio_psa
      _ -> nil
    end
  end

  defp get_active_psa_list(nil, default_list, _override_list), do: default_list

  defp get_active_psa_list({start_time, end_time}, default_list, override_list) do
    now = Timex.now()

    case {Timex.diff(now, start_time), Timex.diff(end_time, now)} do
      {diff1, diff2} when diff1 >= 0 and diff2 > 0 -> override_list
      _ -> default_list
    end
  end

  defp choose_psa(psa_list, :solari) do
    # How often to change the selected PSA
    solari_psa_refresh_seconds = @solari_refresh_seconds * @solari_psa_period

    # Choose which PSA to show, if we're showing one this refresh
    solari_psa = choose_from_rotating_list(psa_list, solari_psa_refresh_seconds)

    # Return either the current PSA or nil
    solari_list = [solari_psa] ++ List.duplicate(nil, @solari_psa_period - 1)
    choose_from_rotating_list(solari_list, @solari_refresh_seconds)
  end

  defp choose_psa(psa_list, app_id) when app_id in ~w[bus_eink gl_eink_single gl_eink_double]a do
    choose_from_rotating_list(psa_list, @eink_refresh_seconds)
  end

  defp choose_from_rotating_list([], _), do: nil
  defp choose_from_rotating_list([psa], _), do: psa

  defp choose_from_rotating_list(list, seconds_to_show) do
    t = DateTime.utc_now()
    seconds_since_midnight = t.hour * 60 * 60 + t.minute * 60 + t.second
    periods_since_midnight = div(seconds_since_midnight, seconds_to_show)
    current_index = rem(periods_since_midnight, length(list))
    Enum.at(list, current_index)
  end
end
