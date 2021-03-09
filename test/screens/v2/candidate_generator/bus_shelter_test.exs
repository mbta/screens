defmodule Screens.V2.CandidateGenerator.BusShelterTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Predictions.Prediction
  alias Screens.V2.CandidateGenerator.BusShelter
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias Screens.V2.WidgetInstance.{Departures, DeparturesNoData, StaticImage}

  describe "candidate_templates/0" do
    test "returns ok" do
      assert :ok = BusShelter.candidate_templates()
    end
  end

  describe "candidate_instances/1" do
    test "returns departure, alert, and static image widget instances" do
      prediction_fetcher = fn _params -> {:ok, List.duplicate(%Prediction{}, 3)} end
      alert_fetcher = fn _params -> List.duplicate(%Alert{}, 2) end

      assert [%Departures{}, %AlertWidget{}, %AlertWidget{}, %StaticImage{}, %StaticImage{}] =
               BusShelter.candidate_instances(:ok, prediction_fetcher, alert_fetcher)
    end

    test "returns a DeparturesNoData widget if prediction fetcher returns :error" do
      prediction_fetcher = fn _params -> :error end
      alert_fetcher = fn _params -> List.duplicate(%Alert{}, 2) end

      assert [%DeparturesNoData{}, %AlertWidget{}, %AlertWidget{}, %StaticImage{}, %StaticImage{}] =
               BusShelter.candidate_instances(:ok, prediction_fetcher, alert_fetcher)
    end
  end
end
