defmodule Screens.TestSupport.InformedEntityBuilder do
  @moduledoc """
  Provides a function that generates InformedEntity structs
  with less boilerplate for testing purposes.
  """
  alias Screens.Alerts.InformedEntity
  alias Screens.Stops.Stop

  def ie(opts \\ []) do
    %InformedEntity{
      stop: if(is_nil(opts[:stop_id]), do: opts[:stop], else: %Stop{id: opts[:stop_id]}),
      route: opts[:route],
      route_type: opts[:route_type],
      direction_id: opts[:direction_id]
    }
  end
end
