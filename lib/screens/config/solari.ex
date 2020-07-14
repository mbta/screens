defmodule Screens.Config.Solari do
  alias Screens.Config.{AudioPsa, PsaList, Solari.Section}

  @type t :: %__MODULE__{
          station_name: String.t(),
          overhead: boolean(),
          section_headers: :normal | :vertical | nil,
          sections: list(Section.t()),
          psa_list: PsaList.t(),
          audio_psa: AudioPsa.t()
        }

  @default_station_name ""
  @default_overhead false
  @default_section_headers :normal

  defstruct station_name: @default_station_name,
            overhead: @default_overhead,
            section_headers: @default_section_headers,
            sections: [],
            psa_list: PsaList.from_json(:default),
            audio_psa: AudioPsa.from_json(:default)

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    station_name = Map.get(json, "station_name", :default)
    overhead = Map.get(json, "overhead", :default)
    section_headers = Map.get(json, "section_headers", :default)

    sections = Map.get(json, "sections", [])
    sections = if is_list(sections), do: sections, else: []

    psa_list = Map.get(json, "psa_list", :default)
    audio_psa = Map.get(json, "audio_psa", :default)

    %__MODULE__{
      station_name: station_name_from_json(station_name),
      overhead: overhead_from_json(overhead),
      section_headers: section_headers_from_json(section_headers),
      sections: Enum.map(sections, &Section.from_json/1),
      psa_list: PsaList.from_json(psa_list),
      audio_psa: AudioPsa.from_json(audio_psa)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{
        station_name: station_name,
        overhead: overhead,
        section_headers: section_headers,
        sections: sections,
        psa_list: psa_list,
        audio_psa: audio_psa
      }) do
    %{
      "station_name" => station_name,
      "overhead" => overhead,
      "section_headers" => section_headers_to_json(section_headers),
      "sections" => Enum.map(sections, &Section.to_json/1),
      "psa_list" => PsaList.to_json(psa_list),
      "audio_psa" => AudioPsa.to_json(audio_psa)
    }
  end

  defp station_name_from_json(name) when is_binary(name) do
    name
  end

  defp station_name_from_json(_) do
    @default_station_name
  end

  defp overhead_from_json(overhead) when is_boolean(overhead) do
    overhead
  end

  defp overhead_from_json(_) do
    @default_overhead
  end

  for headers <- ~w[normal vertical nil]a do
    headers_string = Atom.to_string(headers)

    defp section_headers_from_json(unquote(headers_string)) do
      unquote(headers)
    end

    defp section_headers_to_json(unquote(headers)) do
      unquote(headers_string)
    end
  end

  defp section_headers_from_json(_) do
    @default_section_headers
  end
end
