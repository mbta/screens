defmodule ScreensWeb.UserAgent do
  @moduledoc false

  def is_screen_conn?(conn) do
    conn.req_headers
    |> Enum.into(%{})
    |> Map.get("user-agent")
    |> is_screen?()
  end

  def is_screen?(nil), do: false

  def is_screen?(user_agent) do
    is_mercury?(user_agent) or is_gds?(user_agent) or is_solari?(user_agent) or
      is_dup?(user_agent)
  end

  defp is_mercury?(user_agent) do
    String.contains?(user_agent, "(X11; Linux x86_64)") and
      String.contains?(user_agent, "Version/8.0")
  end

  defp is_gds?(user_agent) do
    String.contains?(user_agent, "einkapp-qt")
  end

  defp is_solari?(user_agent) do
    is_solari_old?(user_agent) or is_solari_new?(user_agent)
  end

  defp is_solari_new?(user_agent) do
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
