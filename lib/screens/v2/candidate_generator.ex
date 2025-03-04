defmodule Screens.V2.CandidateGenerator do
  @moduledoc false

  alias Screens.V2.ScreenData.QueryParams
  alias Screens.V2.WidgetInstance
  alias ScreensConfig.Screen

  @doc """
  Returns the template for this screen.
  """
  @callback screen_template(Screen.t()) :: Screens.V2.Template.template()

  @doc """
  Fetches data and returns a list of candidate widget instances to be
  considered for placement on the template.
  """
  @callback candidate_instances(Screen.t(), QueryParams.t()) :: [WidgetInstance.t()]

  @doc """
  Receives the finalized list of widget instances that were placed on
  the template and have defined audio equivalence, as well as screen config,
  and returns a list of zero or more audio-only widgets to be added to the readout.
  """
  @callback audio_only_instances(widgets :: [WidgetInstance.t()], config :: Screen.t()) ::
              [WidgetInstance.t()]
end
