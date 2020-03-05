defmodule Screens.Override.Fetch do
  @moduledoc false

  @default_opts [timeout: 2000, recv_timeout: 2000]

  def fetch_config_from_s3(opts \\ []) do
    url = "https://mbta-dotcom.s3.amazonaws.com/screens/config/config.json"
    headers = []

    {:ok, %{status_code: 200, body: body}} =
      HTTPoison.get(url, headers, Keyword.merge(@default_opts, opts))

    %{"disabled_screen_ids" => disabled_screen_ids, "globally_disabled" => globally_disabled} =
      Jason.decode!(body)

    %{globally_disabled: globally_disabled, disabled_screen_ids: MapSet.new(disabled_screen_ids)}
  end
end
