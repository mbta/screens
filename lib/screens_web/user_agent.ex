defmodule ScreensWeb.UserAgent do
  @moduledoc false

  @solari_screen_id_range MapSet.new(300..399, &Integer.to_string/1)

  def is_screen_conn?(conn, screen_id) do
    user_agent =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("user-agent")

    is_screen?(user_agent, conn, screen_id)
  end

  def is_screen?(nil, _, _), do: false

  def is_screen?(user_agent, %{params: params}, screen_id) do
    is_mercury?(user_agent) or is_gds?(user_agent) or is_solari?(user_agent, screen_id) or
      is_dup?(user_agent) or is_real_screen_via_query_param?(params)
  end

  defp is_real_screen_via_query_param?(%{"is_real_screen" => "true"}), do: true
  defp is_real_screen_via_query_param?(_), do: false

  defp is_mercury?(user_agent) do
    String.contains?(user_agent, "(X11; Linux x86_64)") and
      String.contains?(user_agent, "Version/8.0")
  end

  defp is_gds?(user_agent) do
    String.contains?(user_agent, "einkapp-qt")
  end

  defp is_solari?(user_agent, screen_id) do
    screen_id in @solari_screen_id_range and
      (is_solari_old?(user_agent) or is_solari_new?(user_agent))
  end

  defp is_solari_new?(user_agent) do
    is_solari_browser_new?(user_agent) or is_10pp_browser?(user_agent)
  end

  defp is_solari_browser_new?(user_agent) do
    firefox_major_version =
      case Regex.run(~r|Firefox/([\d]+)|, user_agent, capture: :all_but_first) do
        nil -> 0
        [version_string] -> String.to_integer(version_string)
      end

    String.contains?(user_agent, "Mozilla/5.0 (X11; Ubuntu; Linux x86_64;") and
      firefox_major_version >= 84
  end

  defp is_10pp_browser?(user_agent) do
    String.contains?(user_agent, "BrightSign/L2D674000659/6.2.94")
  end

  defp is_solari_old?(user_agent) do
    is_solari_audio_old?(user_agent) or is_solari_browser_old?(user_agent)
  end

  defp is_solari_audio_old?(user_agent) do
    String.contains?(user_agent, "MPlayer")
  end

  defp is_solari_browser_old?(user_agent) do
    String.contains?(user_agent, "(X11; Ubuntu; Linux i686; rv:22.0)") and
      String.contains?(user_agent, "Firefox/22.0")
  end

  defp is_dup?(user_agent) do
    user_agent == "okhttp/3.8.0"
  end
end
