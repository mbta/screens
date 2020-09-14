defmodule Screens.Config.Solari do
  @moduledoc false

  alias Screens.Config.{AudioPsa, PsaConfig, Solari.Section}
  alias Screens.Util

  @type t :: %__MODULE__{
          station_name: String.t(),
          overhead: boolean(),
          section_headers: :normal | :vertical | :none,
          sections: list(Section.t()),
          psa_config: PsaConfig.t(),
          audio_psa: AudioPsa.t()
        }

  @enforce_keys [:station_name]
  defstruct station_name: nil,
            overhead: false,
            section_headers: :normal,
            sections: [],
            psa_config: PsaConfig.from_json(:default),
            audio_psa: AudioPsa.from_json(:default)

  @spec from_json(map()) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  for headers <- ~w[normal vertical none]a do
    headers_string = Atom.to_string(headers)

    defp value_from_json("section_headers", unquote(headers_string)) do
      unquote(headers)
    end
  end

  defp value_from_json("sections", sections) when is_list(sections) do
    Enum.map(sections, &Section.from_json/1)
  end

  defp value_from_json("psa_config", psa_config) do
    PsaConfig.from_json(psa_config)
  end

  defp value_from_json("audio_psa", audio_psa) do
    AudioPsa.from_json(audio_psa)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:sections, sections) do
    Enum.map(sections, &Section.to_json/1)
  end

  defp value_to_json(:psa_config, psa_config) do
    PsaConfig.to_json(psa_config)
  end

  defp value_to_json(:audio_psa, audio_psa) do
    AudioPsa.to_json(audio_psa)
  end

  defp value_to_json(_, value), do: value
end
