defmodule Screens.Util do
  @moduledoc false

  def format_time(t) do
    t |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end
end
