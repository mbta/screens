defmodule Screens.Config.Solari.Section.Query do
  alias Screens.Config.Solari.Section.Query.{Opts, Params}

  @type t :: %__MODULE__{
          params: Params.t(),
          opts: Opts.t()
        }

  defstruct params: Params.from_json(:default),
            opts: Opts.from_json(:default)

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    params = Map.get(json, "params", :default)
    opts = Map.get(json, "opts", :default)

    %__MODULE__{
      params: Params.from_json(params),
      opts: Opts.from_json(opts)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{params: params, opts: opts}) do
    %{
      "params" => Params.to_json(params),
      "opts" => Opts.to_json(opts)
    }
  end
end
