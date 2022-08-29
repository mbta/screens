defmodule Screens.BlueBikes.ClientBehaviour do
  @moduledoc false

  @callback fetch_station_information() :: {:ok, map()} | :error
  @callback fetch_station_status() :: {:ok, map()} | :error
end

defmodule Screens.BlueBikes.Client do
  @moduledoc """
  Fetches data from the BlueBikes GBFS feed.
  """
  @behaviour Screens.BlueBikes.ClientBehaviour

  require Logger

  @request_opts [
    timeout: 2000,
    recv_timeout: 2000,
    hackney: [pool: :blue_bikes_pool, checkout_timeout: 4000]
  ]

  @impl true
  @doc "Fetches and JSON-decodes station_information.json."
  @spec fetch_station_information() :: {:ok, map()} | :error
  def fetch_station_information do
    do_fetch(information_url())
  end

  @impl true
  @doc "Fetches and JSON-decodes station_status.json."
  @spec fetch_station_status() :: {:ok, map()} | :error
  def fetch_station_status do
    do_fetch(status_url())
  end

  defp do_fetch(url) do
    with {:ok, response} <- request(url),
         {:ok, body} <- check_response(response) do
      decode_body(body)
    end
  end

  defp request(url) when is_binary(url) do
    case HTTPoison.get(url, [], @request_opts) do
      {:ok, response} ->
        {:ok, response}

      {:error, httpoison_error} ->
        log_api_error("blue bikes api fetch error",
          requested_url: url,
          message: Exception.message(httpoison_error)
        )

        :error
    end
  end

  defp check_response(%{status_code: 200, body: body}), do: {:ok, body}

  defp check_response(%{status_code: status_code, body: body}) do
    log_api_error("blue bikes api bad response", status_code: status_code, body: body)
    :error
  end

  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, decoded} ->
        {:ok, decoded}

      {:error, jason_error} ->
        log_api_error("blue bikes api bad JSON", message: Exception.message(jason_error))
        :error
    end
  end

  defp log_api_error(name, fields) do
    Logger.info("[#{name}] #{Enum.map_join(fields, " ", &format_field/1)}")
  end

  defp format_field({key, value}), do: "#{key}=\"#{value}\""

  defp information_url do
    Application.fetch_env!(:screens, :blue_bikes_station_information_url)
  end

  defp status_url do
    Application.fetch_env!(:screens, :blue_bikes_station_status_url)
  end
end

defmodule Screens.BlueBikes.FakeClient do
  @moduledoc false

  @behaviour Screens.BlueBikes.ClientBehaviour

  @response %{"data" => %{"stations" => []}, "last_updated" => 0}

  @impl true
  def fetch_station_information, do: {:ok, @response}

  @impl true
  def fetch_station_status, do: {:ok, @response}
end
