defmodule Screens.Config.AudioPsa do
  @moduledoc false

  @type t :: {:plaintext | :ssml, String.t()} | nil

  @default_psa_type :plaintext

  @spec from_json(map() | :default) :: t()
  def from_json(%{"type" => type, "text" => text}) when is_binary(text) do
    {type_from_json(type), text}
  end

  def from_json(_) do
    nil
  end

  @spec to_json(t()) :: map()
  def to_json({type, text}) do
    %{
      "type" => type_to_json(type),
      "text" => text
    }
  end

  def to_json(nil), do: nil

  for type <- ~w[plaintext ssml]a do
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
