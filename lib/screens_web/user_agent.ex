defmodule ScreensWeb.UserAgent do
  @moduledoc false

  def is_screen_conn?(conn) do
    user_agent =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("user-agent")

    is_screen?(user_agent, conn)
  end

  def is_screen?(nil, _), do: false

  def is_screen?(user_agent, %{params: params}) do
    is_dup?(user_agent) or is_real_screen_via_query_param?(params)
  end

  defp is_real_screen_via_query_param?(%{"is_real_screen" => "true"}), do: true
  defp is_real_screen_via_query_param?(_), do: false

  defp is_dup?(user_agent) do
    user_agent == "okhttp/3.8.0"
  end
end
