defmodule Screens.Cache.Client do
  @moduledoc """
  Provides some conveniences for a cache client module:
  - @table attribute for use within the module
  - table/0 exposes @table publicly, mostly for use by engine module
  - table_exists?/0 checks if table exists
  - with_table macro wraps code in a table_exists?() check,
    returns error tuple if table is missing
  """

  defmacro __using__(table: table) do
    quote do
      @table unquote(table)
      def table, do: @table

      defmacrop with_table(do: block) do
        quote do
          if table_exists?() do
            unquote(block)
          else
            {:error, "ETS table #{inspect(@table)} does not exist"}
          end
        end
      end

      defp table_exists? do
        :ets.whereis(@table) != :undefined
      end
    end
  end
end
