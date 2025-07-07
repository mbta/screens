defmodule Screens.Memcache do
  @moduledoc "Convenience module for connecting to the app's Memcached instance."

  @doc "Start a connection."
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(server_opts \\ []) do
    :screens
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.put(:coder, {Memcache.Coder.Erlang, [:safe]})
    |> Memcache.start_link(server_opts)
  end
end
