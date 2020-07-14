defmodule Screens.Config.AudioPsa do
  @type t :: %__MODULE__{
          type: :plaintext | :ssml,
          text: String.t()
        }

  @default_psa_type :plaintext

  defstruct type: @default_psa_type,
            text: ""

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    type = Map.get(json, "type", :default)
    text = Map.get(json, "text", "")

    %__MODULE__{
      type: type_from_json(type),
      text: text
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{type: type, text: text}) do
    %{
      "type" => type_to_json(type),
      "text" => text
    }
  end

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
