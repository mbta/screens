defmodule Screens.Config.Solari.Section.Layout do
  alias Screens.Config.Solari.Section.Layout.{BidirectionalOpts, UpcomingOpts}

  @type t ::
          %__MODULE__{
            type: :bidirectional,
            opts: BidirectionalOpts.t()
          }
          | %__MODULE__{
              type: :upcoming,
              opts: UpcomingOpts.t()
            }

  @default_type :upcoming

  @opts_modules %{
    bidirectional: BidirectionalOpts,
    upcoming: UpcomingOpts
  }

  defstruct type: @default_type,
            opts: @opts_modules[@default_type].from_json(:default)

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    type = Map.get(json, "type", :default)
    opts = Map.get(json, "opts", :default)

    %__MODULE__{
      type: type_from_json(type),
      opts: opts_from_json(opts, type)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{type: type, opts: opts}) do
    %{
      "type" => type_to_json(type),
      "opts" => opts_to_json(opts, type)
    }
  end

  for type <- ~w[bidirectional upcoming]a do
    type_string = Atom.to_string(type)

    opts_module = @opts_modules[type]

    defp type_from_json(unquote(type_string)) do
      unquote(type)
    end

    defp type_to_json(unquote(type)) do
      unquote(type_string)
    end

    defp opts_from_json(opts, unquote(type_string)) do
      unquote(opts_module).from_json(opts)
    end

    defp opts_to_json(opts, unquote(type)) do
      unquote(opts_module).to_json(opts)
    end
  end

  defp type_from_json(_) do
    :upcoming
  end

  defp opts_from_json(_, _) do
    @opts_modules[@default_type].from_json(:default)
  end
end
