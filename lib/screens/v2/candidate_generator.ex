defmodule Screens.V2.CandidateGenerator do
  @moduledoc false

  alias Screens.V2.ScreenData

  @callback candidate_templates() :: Screens.V2.Template.template()

  @callback candidate_instances(ScreenData.config()) :: ScreenData.candidate_instances()
end
