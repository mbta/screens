defmodule Screens.Config.Struct do
  @moduledoc """
  A `use`-able convenience macro that generates boilerplate code for
  a JSON-serializable config struct. Modules that use this will automatically
  adopt `Screens.Config.Behaviour`.

  This shouldn't be used in all cases--it's just for the more straightforward
  pieces of config.

  In the using module, you MUST define the following:

    * A struct

    * A `t()` type definition for the struct

    * `value_from_json/2` and `value_to_json/2`, if you do not pass a `children` list in the `use` call

  You MAY also define the following:

    * Additional clauses of `value_from_json/2` and `value_to_json/2`

  ## Options

    * `:with_default` - set true to have the generated `from_json/1` accept `:default` as its argument.
      Default false.

    * `:children` - pass a keyword list of {struct_key, child_config_module | {:list, child_config_module}},
      where child_config_module is a module that adopts `Screens.Config.Behaviour`.
  """

  @type opt ::
          {:with_default, boolean()}
          | {:children, keyword(module() | {:list, module()})}

  @type opts :: list(opt())

  @spec __using__(opts()) :: term()
  defmacro __using__(opts \\ []) do
    with_default = opts[:with_default] || false
    children = opts[:children] || []

    quote location: :keep, bind_quoted: [with_default: with_default, children: children] do
      alias Screens.Util

      @behaviour Screens.Config.Behaviour

      @impl true
      if with_default do
        @spec from_json(map() | :default) :: t()
      else
        @spec from_json(map()) :: t()
      end

      def from_json(%{} = json) do
        struct_map =
          json
          |> Map.take(Util.struct_keys(__MODULE__))
          |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

        struct!(__MODULE__, struct_map)
      end

      if with_default do
        def from_json(:default), do: %__MODULE__{}
      end

      @impl true
      @spec to_json(t()) :: map()
      def to_json(%__MODULE__{} = t) do
        t
        |> Map.from_struct()
        |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
      end

      defp value_from_json(string_key, value)

      defp value_to_json(key, value)

      for {key, child_module} <- children do
        string_key = Atom.to_string(key)

        case child_module do
          {:list, module} ->
            defp value_from_json(unquote(string_key), values) do
              Enum.map(values, &unquote(module).from_json/1)
            end

            defp value_to_json(unquote(key), values) do
              Enum.map(values, &unquote(module).to_json/1)
            end

          module ->
            defp value_from_json(unquote(string_key), value) do
              unquote(module).from_json(value)
            end

            defp value_to_json(unquote(key), value) do
              unquote(module).to_json(value)
            end
        end
      end

      defoverridable value_from_json: 2, value_to_json: 2
    end
  end
end
