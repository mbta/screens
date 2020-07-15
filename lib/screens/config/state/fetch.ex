defmodule Screens.Config.State.Fetch do
  alias Screens.Config

  @default_opts [timeout: 2000, recv_timeout: 2000]

  @spec fetch_config(keyword()) :: {:ok, Config.t()} | :error
  def fetch_config(opts \\ []) do
    url = "https://mbta-dotcom.s3.amazonaws.com/screens/config/" <> config_path_for_environment()
    headers = []

    with {:ok, response} <- HTTPoison.get(url, headers, Keyword.merge(@default_opts, opts)),
         %{status_code: 200, body: body} <- response,
         {:ok, parsed} <- Jason.decode(body) do
      {:ok, Config.from_json(parsed)}
    else
      _ -> :error
    end
  end

  defp config_path_for_environment do
    case Application.get_env(:screens, :environment_name) do
      "screens-prod" -> "prod.json"
      "screens-dev" -> "dev.json"
      "screens-dev-green" -> "dev-green.json"
    end
  end
end
