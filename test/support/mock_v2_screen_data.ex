defmodule Screens.V2.MockScreenData do
  @doc "A fake screen-data-fetching function to be used during tests, to avoid making requests."
  def get(screen_id, _opts \\ []) do
    %{content: "mock screen data for screen #{screen_id}"}
  end
end
