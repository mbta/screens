defmodule Screens.Config.AudioPsa do
  @moduledoc false

  @behaviour Screens.Config.Behaviour

  @type t :: {format, String.t(), type} | nil

  @typep format :: :plaintext | :ssml
  @typep type :: :takeover | :end

  @default_psa_format :plaintext
  @default_psa_type :end

  @impl true
  @spec from_json(map() | :default) :: t()
  def from_json(%{"format" => format, "name" => name, "type" => type}) when is_binary(name) do
    {format_from_json(format), name, type_from_json(type)}
  end

  def from_json(_) do
    nil
  end

  @impl true
  @spec to_json(t()) :: map()
  def to_json({format, name, type}) do
    %{
      format: format_to_json(format),
      name: name,
      type: type_to_json(type)
    }
  end

  def to_json(nil), do: nil

  for format <- ~w[plaintext ssml]a do
    format_string = Atom.to_string(format)

    defp format_from_json(unquote(format_string)) do
      unquote(format)
    end

    defp format_to_json(unquote(format)) do
      unquote(format_string)
    end
  end

  defp format_from_json(_) do
    @default_psa_format
  end

  for type <- ~w[takeover end]a do
    type_string = Atom.to_string(type)

    defp type_from_json(unquote(type_string)) do
      unquote(type)
    end

    defp type_to_json(unquote(type)) do
      unquote(type_string)
    end
  end

  defp type_from_json(_) do
    @default_psa_type
  end
end
