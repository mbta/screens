defmodule Screens.Config.PsaList do
  @moduledoc false

  @type t :: {
          psa_type,
          list(String.t())
        }

  @default_psa_type nil

  @type psa_type :: bus_psa_type | gl_psa_type | solari_psa_type | nil

  @type bus_psa_type :: :double | :takeover
  @type gl_psa_type :: :double | :takeover | :departure
  @type solari_psa_type :: :psa | :takeover

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    type = Map.get(json, "type", :default)
    paths = Map.get(json, "paths", [])
    paths = if is_list(paths), do: paths, else: []

    {type_from_json(type), paths}
  end

  def from_json(:default) do
    {@default_psa_type, []}
  end

  @spec to_json(t) :: map()
  def to_json({type, paths}) do
    %{
      type: type,
      paths: paths
    }
  end

  for psa_type <- ~w[psa double takeover departure]a do
    psa_type_string = Atom.to_string(psa_type)

    defp type_from_json(unquote(psa_type_string)) do
      unquote(psa_type)
    end
  end

  defp type_from_json(_) do
    @default_psa_type
  end
end
