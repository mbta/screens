defmodule Screens.V2.CandidateGenerator do
  @moduledoc false

  alias Screens.V2.WidgetInstance
  alias ScreensConfig.Screen

  defmodule Timeout do
    defexception message: "Candidate generation timed out", plug_status: 503
  end

  @doc """
  Returns the template for this screen.
  """
  @callback screen_template(Screen.t()) :: Screens.V2.Template.template()

  @doc """
  Fetches data and returns a list of candidate widget instances to be
  considered for placement on the template.
  """
  @callback candidate_instances(Screen.t()) :: [WidgetInstance.t()]

  @doc """
  Receives the finalized list of widget instances that were placed on
  the template and have defined audio equivalence, as well as screen config,
  and returns a list of zero or more audio-only widgets to be added to the readout.
  """
  @callback audio_only_instances(widgets :: [WidgetInstance.t()], config :: Screen.t()) ::
              [WidgetInstance.t()]

  @doc """
  Convenience wrapper around `Task.async_stream/3` for running several candidate generation
  functions in parallel, raising `Screens.Timeout` if any exceed a timeout.
  """
  @spec async_stream(Enumerable.t(), (term() -> term())) :: Enumerable.t()
  @spec async_stream(Enumerable.t(), (term() -> term()), [Task.async_stream_option()]) ::
          Enumerable.t()
  def async_stream(enum, func, options \\ []) do
    enum
    |> Task.async_stream(func, Keyword.merge(options, on_timeout: :kill_task))
    |> Enum.flat_map(fn
      {:ok, instances} -> instances
      {:exit, :timeout} -> raise Timeout
    end)
  end
end
