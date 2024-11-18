defmodule Screens.Inject do
  @moduledoc "Conveniences for dependency injection and mocking."

  @doc """
  When the Mix env is not `test`, resolves to the given module name. When it is, resolves to the
  module name with `.Mock` appended.

  The mock module is not automatically defined (see e.g. `test/support/mocks.ex`).

  Example usage:

      defmodule Screens.Foo do
        import Screens.Inject

        @dependency injected(Screens.Dependency)

        def do_something, do: @dependency.fetch_data()
      end
  """
  defmacro injected(module) do
    quote do
      module = unquote(module)
      if Mix.env() == :test, do: Module.concat(module, "Mock"), else: module
    end
  end
end
