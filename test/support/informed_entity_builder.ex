defmodule Screens.TestSupport.InformedEntityBuilder do
  @moduledoc """
  Provides a function that generates InformedEntity structs
  with less boilerplate for testing purposes.
  """
  alias Screens.Alerts.InformedEntity
  alias Screens.Stops.Stop

  def ie(opts \\ []) do
    %InformedEntity{
      stop: if(opts[:stop_id], do: %Stop{id: opts[:stop_id]}, else: opts[:stop]),
      # TODO(RW): Temporary for the current PR stack. To lessen the review burden, many of the
      # mechanical changes have been put in a single PR in a review stack. The next PR in the
      # stack will replace the body of the `if` to return a %Route{}
      route: if(opts[:route_id], do: opts[:route_id], else: opts[:route]),
      route_type: opts[:route_type],
      direction_id: opts[:direction_id]
    }
  end
end
