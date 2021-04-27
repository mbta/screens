defmodule Screens.Config.V2.Departures.Query do
  @moduledoc false

  alias Screens.Config.V2.Departures.Query.{Opts, Params}
  alias Screens.Util

  @type t :: %__MODULE__{
          params: Params.t(),
          opts: Opts.t()
        }

  defstruct params: Params.from_json(:default),
            opts: Opts.from_json(:default)

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

  defp value_from_json("params", params) do
    Params.from_json(params)
  end

  defp value_from_json("opts", opts) do
    Opts.from_json(opts)
  end

  defp value_to_json(:params, params) do
    Params.to_json(params)
  end

  defp value_to_json(:opts, opts) do
    Opts.to_json(opts)
  end
end
