defmodule Screens.Config.Solari do
  @moduledoc false

  alias Screens.Config.{AudioPsa, PsaConfig, Solari.Section}

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

  use Screens.Config.Struct,
    children: [sections: {:list, Section}, psa_config: PsaConfig, audio_psa: AudioPsa]

  for headers <- ~w[normal vertical none]a do
    headers_string = Atom.to_string(headers)

    defp value_from_json("section_headers", unquote(headers_string)) do
      unquote(headers)
    end
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
