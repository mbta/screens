defmodule Screens.V2.CandidateGenerator.BusShelterTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Predictions.Prediction
  alias Screens.V2.CandidateGenerator.BusShelter
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget

  alias Screens.V2.WidgetInstance.{
    Departures,
    DeparturesNoData,
    NormalFooter,
    NormalHeader,
    StaticImage
  }

  describe "candidate_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                normal: [
                  :header,
                  :main_content,
                  {:flex_zone,
                   %{
                     one_large: [:large],
                     one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
                     two_medium: [:medium_left, :medium_right]
                   }},
                  :footer
                ],
                takeover: [:fullscreen]
              }} == BusShelter.candidate_template()
    end
  end

  describe "candidate_instances/1" do
    test "returns departure, alert, and static image widget instances" do
      prediction_fetcher = fn _params -> {:ok, List.duplicate(%Prediction{}, 3)} end
      alert_fetcher = fn _params -> List.duplicate(%Alert{}, 2) end

      assert [
               %Departures{},
               %AlertWidget{},
               %AlertWidget{},
               %StaticImage{},
               %StaticImage{},
               %NormalHeader{},
               %NormalFooter{}
             ] = BusShelter.candidate_instances(:ok, prediction_fetcher, alert_fetcher)
    end

    test "returns a DeparturesNoData widget if prediction fetcher returns :error" do
      prediction_fetcher = fn _params -> :error end
      alert_fetcher = fn _params -> List.duplicate(%Alert{}, 2) end

      assert [
               %DeparturesNoData{},
               %AlertWidget{},
               %AlertWidget{},
               %StaticImage{},
               %StaticImage{},
               %NormalHeader{},
               %NormalFooter{}
             ] = BusShelter.candidate_instances(:ok, prediction_fetcher, alert_fetcher)
    end
  end
end
