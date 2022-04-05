defmodule Screens.V2.CandidateGenerator do
  @moduledoc false

  alias Screens.V2.ScreenData

  @callback screen_template() :: Screens.V2.Template.template()

  @callback candidate_instances(ScreenData.config()) :: ScreenData.candidate_instances()

  @callback insert_global_audio_instances(
              widgets :: ScreenData.candidate_instances(),
              config :: ScreenData.config()
            ) :: ScreenData.candidate_instances()
end
