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

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                normal: [
                  :header,
                  :main_content,
                  {{0, :flex_zone},
                   %{
                     one_large: [{0, :large}],
                     one_medium_two_small: [
                       {0, :medium_left},
                       {0, :small_upper_right},
                       {0, :small_lower_right}
                     ],
                     two_medium: [{0, :medium_left}, {0, :medium_right}]
                   }},
                  {{1, :flex_zone},
                   %{
                     one_large: [{1, :large}],
                     one_medium_two_small: [
                       {1, :medium_left},
                       {1, :small_upper_right},
                       {1, :small_lower_right}
                     ],
                     two_medium: [{1, :medium_left}, {1, :medium_right}]
                   }},
                  {{2, :flex_zone},
                   %{
                     one_large: [{2, :large}],
                     one_medium_two_small: [
                       {2, :medium_left},
                       {2, :small_upper_right},
                       {2, :small_lower_right}
                     ],
                     two_medium: [{2, :medium_left}, {2, :medium_right}]
                   }},
                  :footer
                ],
                takeover: [:full_screen]
              }} == BusShelter.screen_template()
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
