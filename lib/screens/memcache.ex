defmodule Screens.Memcache do
  @moduledoc "Convenience module for connecting to the app's Memcached instance."

  @doc "Start a connection."
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(server_opts \\ []) do
    :screens
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.put(:coder, __MODULE__.SafeErlangCoder)
    |> Memcache.start_link(server_opts)
  end

  defmodule SafeErlangCoder do
    @moduledoc """
    Erlang coder which uses the `:safe` option to prevent runtime creation of atoms and other
    values that aren't garbage-collected.

    Must be implemented this way rather than setting `coder: {Memcache.Coder.Erlang, [:safe]}`
    because the `:safe` option would be applied to both the `binary_to_term` and `term_to_binary`
    calls, but it is not a valid option for the latter, causing a crash.
    """
    @behaviour Memcache.Coder

    @impl true
    def encode(value, _options), do: :erlang.term_to_binary(value)

    @impl true
    def decode(value, _options), do: :erlang.binary_to_term(value, [:safe])
  end
end
