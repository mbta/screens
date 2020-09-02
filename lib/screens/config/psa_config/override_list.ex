defmodule Screens.Config.PsaConfig.OverrideList do
  @moduledoc false

  alias Screens.Config.PsaConfig.PsaList
  alias Screens.Util

  @type t :: %__MODULE__{
          psa_list: PsaList.t(),
          start_time: DateTime.t() | nil,
          end_time: DateTime.t() | nil
        }

  defstruct psa_list: PsaList.from_json(:default),
            start_time: nil,
            end_time: nil

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  for datetime_key <- ~w[start_time end_time]a do
    datetime_key_string = Atom.to_string(datetime_key)

    defp value_from_json(unquote(datetime_key_string), nil), do: nil

    defp value_from_json(unquote(datetime_key_string), timestamp) do
      timestamp
      |> DateTime.from_iso8601()
      # TODO: should we just let parsing fail if this receives an invalid timestamp, instead of falling back on nil?
      |> case do
        {:ok, dt, _offset} -> dt
        _ -> nil
      end
    end

    defp value_to_json(unquote(datetime_key), nil), do: nil

    defp value_to_json(unquote(datetime_key), datetime) do
      DateTime.to_iso8601(datetime)
    end
  end

  defp value_from_json("psa_list", psa_list) do
    PsaList.from_json(psa_list)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:psa_list, psa_list) do
    PsaList.to_json(psa_list)
  end

  defp value_to_json(_, value), do: value

end
