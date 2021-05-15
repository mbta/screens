defmodule Screens.Config.Solari.Section.Layout do
  @moduledoc false

  alias Screens.Config.Solari.Section.Layout.{Bidirectional, Upcoming}

  @behaviour Screens.Config.Behaviour

  @type t ::
          Bidirectional.t()
          | Upcoming.t()

  @default_type :upcoming

  @opts_modules %{
    bidirectional: Bidirectional,
    upcoming: Upcoming
  }

  @impl true
  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    type = Map.get(json, "type", :default)
    opts = Map.get(json, "opts", :default)

    opts_from_json(opts, type)
  end

  def from_json(:default) do
    @opts_modules[@default_type].from_json(:default)
  end

  @impl true
  @spec to_json(t()) :: map()
  def to_json(%Bidirectional{} = layout) do
    %{
      "type" => "bidirectional",
      "opts" => Bidirectional.to_json(layout)
    }
  end

  def to_json(%Upcoming{} = layout) do
    %{
      "type" => "upcoming",
      "opts" => Upcoming.to_json(layout)
    }
  end

  for type <- ~w[bidirectional upcoming]a do
    type_string = Atom.to_string(type)

    opts_module = @opts_modules[type]

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

  defp opts_from_json(_, _) do
    @opts_modules[@default_type].from_json(:default)
  end
end
