defmodule Screens.V2.CandidateGenerator.DupNew.Departures do
  @moduledoc false

  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}
  alias ScreensConfig.Screen

  @type widget :: DeparturesNoData.t() | DeparturesWidget.t() | OvernightDepartures.t()

  @spec instances(Screen.t(), DateTime.t()) :: [widget()]
  def instances(config, _now) do
    ~w[
      main_content_zero
      main_content_one
      main_content_two
      main_content_reduced_zero
      main_content_reduced_one
      main_content_reduced_two
    ]a
    |> Enum.map(&%DeparturesNoData{screen: config, slot_name: &1})
  end
end
