defmodule Screens.V2.MockScreenData do
  @doc "A fake screen-data-fetching function to be used during tests, to avoid making requests."
  def by_screen_id(screen_id) do
    %{
      data: %{content: "mock screen data for screen #{screen_id}"},
      force_reload: false,
      disabled: false
    }
  end

  def by_screen_id(screen_id, _opts) do
    by_screen_id(screen_id)
  end
end
