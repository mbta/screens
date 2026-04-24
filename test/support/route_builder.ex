defmodule Screens.TestSupport.RouteBuilder do
  @moduledoc """
  Provides a function that generates Route structs
  with less boilerplate for testing purposes.
  """
  alias Screens.Lines.Line
  alias Screens.Routes.Route

  def route(opts) do
    %Route{
      id: opts[:id],
      short_name: opts[:name] || "",
      long_name: opts[:name],
      type: opts[:type],
      line:
        if(opts[:line_id], do: %Line{id: opts[:line_id]}, else: %Line{id: "line-#{opts[:id]}"})
    }
  end
end
