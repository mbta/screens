defmodule Screens.Cache.Client do
  @moduledoc """
  Provides some conveniences for a cache client module.
  """

  defmacro __using__(table: table) do
    quote do
      @table unquote(table)

      @doc """
      Returns the name of the table that this client reads from.
      (Generated by `use Screens.Cache.Client`)
      """
      def table, do: @table

      @doc """
      Wraps a code block in a `table_exists?()` check.

      If the check fails, an `{:error, reason}` tuple is returned.
      (Generated by `use Screens.Cache.Client`)
      """
      defmacro with_table(do: block) do
        quote do
          if table_exists?() do
            unquote(block)
          else
            {:error, "ETS table #{inspect(@table)} does not exist"}
          end
        end
      end

      @doc """
      Returns true if the table that this client reads from exists.
      (Generated by `use Screens.Cache.Client`)
      """
      def table_exists? do
        :ets.whereis(@table) != :undefined
      end
    end
  end
end
