defmodule Screens.Override.Fetch do
  @moduledoc false

  @default_opts [timeout: 2000, recv_timeout: 2000, hackney: [pool: :s3_pool]]

  def fetch_config(opts \\ []) do
    url = "https://mbta-dotcom.s3.amazonaws.com/screens/config/" <> config_path_for_environment()
    headers = []

    with {:ok, response} <- HTTPoison.get(url, headers, Keyword.merge(@default_opts, opts)),
         %{status_code: 200, body: body} <- response,
         {:ok, parsed} <- Jason.decode(body, keys: :atoms) do
      {:ok, Screens.Override.from_json(parsed)}
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
