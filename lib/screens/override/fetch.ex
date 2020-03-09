defmodule Screens.Override.Fetch do
  @moduledoc false

  @default_opts [timeout: 2000, recv_timeout: 2000]

  def fetch_config_from_s3(opts \\ []) do
    url = "https://mbta-dotcom.s3.amazonaws.com/screens/config/" <> config_path_for_environment()
    headers = []

    with {:ok, response} <- HTTPoison.get(url, headers, Keyword.merge(@default_opts, opts)),
         %{status_code: 200, body: body} <- response,
         {:ok, parsed} <- Jason.decode(body),
         %{"disabled_screen_ids" => disabled_screen_ids, "globally_disabled" => globally_disabled} <-
           parsed do
      {:ok,
       %{
         globally_disabled: globally_disabled,
         disabled_screen_ids: MapSet.new(disabled_screen_ids)
       }}
    else
      _ -> :error
    end
  end

  defp config_path_for_environment do
    case Application.get_env(:screens, :environment_name) do
      "screens-prod" -> "prod.json"
      _ -> "dev.json"
    end
  end
end
