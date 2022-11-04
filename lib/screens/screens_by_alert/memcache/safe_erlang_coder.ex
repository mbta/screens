defmodule Screens.ScreensByAlert.Memcache.SafeErlangCoder do
  @moduledoc """
  Uses `:erlang.term_to_binary(term)` and `:erlang.binary_to_term(term, [:safe])` to
  encode and decode values, preventing creation of new atoms and other values that
  aren't garbage-collected.
  """
  @behaviour Memcache.Coder

  @impl true
  def encode(value, _options), do: :erlang.term_to_binary(value)

  @impl true
  def decode(value, _options), do: :erlang.binary_to_term(value, [:safe])
end
