defmodule Screens.Config.Struct do
  @moduledoc """
  A `use`-able convenience macro that generates boilerplate code for
  a JSON-serializable config struct. Modules that use this will automatically
  adopt `Screens.Config.Behaviour`.

  This can be used for most config modules that define structs
  and have straightforward serialization logic.

  ## Options

    * `:with_default` - set true to have the generated `from_json/1` accept `:default` as an argument.
      Default false.

    * `:children` - pass a keyword list of `{struct_key, child | {:list, child} | {:map, child}}`,
      where `child` is a module that adopts `Screens.Config.Behaviour`.

  In the using module, you MUST define the following:

    * A struct

    * A `t()` type definition for the struct

    * Clauses of `value_from_json/2` and `value_to_json/2` for struct fields not described in the `:children` opt

    * Any other fallback clauses of `value_from_json/2` and `value_to_json/2`
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
          |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), _value_from_json(k, v)} end)

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
        |> Enum.into(%{}, fn {k, v} -> {k, _value_to_json(k, v)} end)
      end

      for {key, child_module} <- children do
        string_key = Atom.to_string(key)

        case child_module do
          {:list, module} ->
            defp _value_from_json(unquote(string_key), values) when is_list(values) do
              Enum.map(values, &unquote(module).from_json/1)
            end

            defp _value_to_json(unquote(key), values) do
              Enum.map(values, &unquote(module).to_json/1)
            end

          {:map, module} ->
            defp _value_from_json(unquote(string_key), value_map) when is_map(value_map) do
              Enum.into(value_map, %{}, fn {k, v} -> {k, unquote(module).from_json(v)} end)
            end

            defp _value_to_json(unquote(key), value_map) do
              Enum.into(value_map, %{}, fn {k, v} -> {k, unquote(module).to_json(v)} end)
            end

          module ->
            defp _value_from_json(unquote(string_key), value) when not is_nil(value) do
              unquote(module).from_json(value)
            end

            defp _value_to_json(unquote(key), value) when not is_nil(value) do
              unquote(module).to_json(value)
            end
        end
      end

      defp _value_from_json(key, value), do: value_from_json(key, value)

      defp _value_to_json(key, value), do: value_to_json(key, value)

      defp value_from_json(_key, _value) do
        raise "#{__MODULE__}.value_from_json/2 not implemented"
      end

      defp value_to_json(_key, _value) do
        raise "#{__MODULE__}.value_to_json/2 not implemented"
      end

      defoverridable from_json: 1, to_json: 1, value_from_json: 2, value_to_json: 2
    end
  end
end
