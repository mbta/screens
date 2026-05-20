defprotocol Screens.V2.Precedence do
  @doc """
  A protocol for determining the precedence of widgets with the same priority competing for the same slot.

  Defaults to returning 1, but can be implemented by specific widget types to return 0 to indicate
  higher precedence within the same priority bracket.
  """
  @fallback_to_any true

  @spec rank(t()) :: 0 | 1
  def rank(instance)
end

defimpl Screens.V2.Precedence, for: Any do
  def rank(_instance), do: 1
end
