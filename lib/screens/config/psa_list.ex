defmodule Screens.Config.PsaList do
  @type t :: %__MODULE__{
          type: psa_type,
          paths: list(String.t())
        }

  @default_psa_type :takeover

  @type psa_type :: bus_psa_type | gl_psa_type | solari_psa_type

  @type bus_psa_type :: :double | :takeover
  @type gl_psa_type :: :double | :takeover
  @type solari_psa_type :: :psa | :takeover

  defstruct type: @default_psa_type,
            paths: []

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    type = Map.get(json, "type", :default)
    paths = Map.get(json, "paths", [])
    paths = if is_list(paths), do: paths, else: []

    %__MODULE__{type: type_from_json(type), paths: paths}
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t) :: map()
  def to_json(%__MODULE__{type: type, paths: paths}) do
    %{
      "type" => type_to_json(type),
      "paths" => paths
    }
  end

  for psa_type <- ~w[psa double takeover]a do
    psa_type_string = Atom.to_string(psa_type)

    defp type_from_json(unquote(psa_type_string)) do
      unquote(psa_type)
    end

    defp type_to_json(unquote(psa_type)) do
      unquote(psa_type_string)
    end
  end

  defp type_from_json(_) do
    @default_psa_type
  end
end
