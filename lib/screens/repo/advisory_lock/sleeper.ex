defmodule Screens.Repo.AdvisoryLock.Sleeper do
  @moduledoc "Injectable wrapper around `Process.sleep/1`, so tests don't need to wait in real time."

  @callback sleep(non_neg_integer()) :: :ok
  def sleep(ms), do: Process.sleep(ms)
end
