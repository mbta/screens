defmodule Screens.Config.PsaConfig.OverrideList do
  @moduledoc false

  alias Screens.Config.PsaConfig.PsaList

  @type t :: %__MODULE__{
          psa_list: PsaList.t(),
          start_time: nullable_datetime(),
          end_time: nullable_datetime()
        }

  @typep nullable_datetime :: DateTime.t() | nil

  @enforce_keys ~w[psa_list start_time end_time]a
  defstruct @enforce_keys

  use Screens.Config.Struct, children: [psa_list: PsaList]

  for datetime_key <- ~w[start_time end_time]a do
    datetime_key_string = Atom.to_string(datetime_key)

    defp value_from_json(unquote(datetime_key_string), nil), do: nil

    defp value_from_json(unquote(datetime_key_string), iso_string) do
      {:ok, dt, _offset} = DateTime.from_iso8601(iso_string)
      dt
    end

    defp value_to_json(unquote(datetime_key), nil), do: nil

    defp value_to_json(unquote(datetime_key), datetime) do
      DateTime.to_iso8601(datetime)
    end
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
