defmodule Screens.TestSupport.CandidateGeneratorStub do
  defmacro candidate_generator(name, instances_fn) do
    quote do
      defmodule unquote(name) do
        alias Screens.V2.CandidateGenerator
        alias Screens.V2.Template.Builder
        alias Screens.V2.WidgetInstance.Placeholder

        @behaviour CandidateGenerator

        @impl CandidateGenerator
        def screen_template(_screen), do: Builder.build_template({:screen, %{normal: [:main]}})

        @impl CandidateGenerator
        def candidate_instances(config) do
          unquote(instances_fn).(config)
        end

        @impl CandidateGenerator
        def audio_only_instances(_widgets, _config), do: []

        defp placeholder(color), do: %Placeholder{color: color, slot_names: [:main]}
      end
    end
  end
end
