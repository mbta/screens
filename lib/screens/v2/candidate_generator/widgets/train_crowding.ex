defmodule Screens.V2.CandidateGenerator.Widgets.TrainCrowding do
  @moduledoc false

  require Logger

  alias Screens.Alerts.Alert
  alias Screens.OlCrowding.Agent
  alias Screens.Predictions.Prediction
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.TrainCrowding, as: CrowdingWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{TrainCrowding, Triptych}

  # {parent_station_id, {sb_platform_id, nb_platform_id}}
  @ol_station_to_platform_map [
    {"place-ogmnl", {"70036", "70036"}},
    {"place-mlmnl", {"70034", "70035"}},
    {"place-welln", {"70032", "70033"}},
    {"place-astao", {"70278", "70279"}},
    {"place-sull", {"70030", "70031"}},
    {"place-ccmnl", {"70028", "70029"}},
    {"place-north", {"70026", "70027"}},
    {"place-haecl", {"70024", "70025"}},
    {"place-state", {"70022", "70023"}},
    {"place-dwnxg", {"70020", "70021"}},
    {"place-chncl", {"70018", "70019"}},
    {"place-tumnl", {"70016", "70017"}},
    {"place-bbsta", {"70014", "70015"}},
    {"place-masta", {"70012", "70013"}},
    {"place-rugg", {"70010", "70011"}},
    {"place-rcmnl", {"70008", "70009"}},
    {"place-jaksn", {"70006", "70007"}},
    {"place-sbmnl", {"70004", "70005"}},
    {"place-grnst", {"70002", "70003"}},
    {"place-forhl", {"70001", "70001"}}
  ]

  @spec crowding_widget_instances(Screen.t(), map()) :: list(CrowdingWidget.t())
  def crowding_widget_instances(
        config,
        logging_options,
        now \\ DateTime.utc_now(),
        fetch_predictions_fn \\ &Prediction.fetch/1,
        fetch_location_context_fn \\ &Stop.fetch_location_context/3,
        fetch_parent_stop_id_fn \\ &Stop.fetch_parent_stop_id/1,
        fetch_alerts_fn \\ &Alert.fetch/1
      )

  def crowding_widget_instances(
        %Screen{app_params: %Triptych{train_crowding: %TrainCrowding{enabled: false}}},
        _,
        _,
        _,
        _,
        _,
        _
      ) do
    []
  end

  def crowding_widget_instances(
        %Screen{app_params: %Triptych{train_crowding: train_crowding}} = config,
        logging_options,
        now,
        fetch_predictions_fn,
        fetch_location_context_fn,
        fetch_parent_stop_id_fn,
        fetch_alerts_fn
      ) do
    params = %{
      direction_id: train_crowding.direction_id,
      route_ids: [train_crowding.route_id],
      stop_ids: [train_crowding.station_id]
    }

    with {:ok, predictions} <- fetch_predictions_fn.(params),
         {:ok, location_context} <-
           fetch_location_context_fn.(Triptych, train_crowding.station_id, now),
         {:ok, alerts} <-
           params |> Map.to_list() |> fetch_alerts_fn.() do
      next_train_prediction = List.first(predictions)

      if next_train_prediction && logging_options && logging_options.is_real_screen do
        Logger.info(
          "[train_crowding next_prediction] screen_id=#{logging_options.screen_id} triptych_pane=#{logging_options.triptych_pane} next_trip_id=#{next_train_prediction.trip.id}"
        )
      end

      common_params = %{
        screen_config: config,
        next_train_prediction: next_train_prediction,
        train_crowding_config: train_crowding,
        logging_options: logging_options,
        fetch_parent_stop_id_fn: fetch_parent_stop_id_fn,
        fetch_predictions_fn: fetch_predictions_fn,
        fetch_params: params,
        now: now
      }

      get_instance(
        any_alert_makes_this_a_terminal?(alerts, location_context, now),
        common_params
      )
    else
      :error -> []
    end
  end

  defp get_instance(
         alert_makes_this_a_terminal,
         common_params
       )
       when alert_makes_this_a_terminal or is_nil(common_params.next_train_prediction) or
              common_params.next_train_prediction == [],
       do: []

  defp get_instance(
         _alert_makes_this_a_terminal,
         common_params
       ) do
    next_train_prediction = common_params.next_train_prediction

    # If there is an upcoming train, it's headed to this station,
    # and we're not at a temporary terminal, log the widget.
    if Prediction.vehicle_status(next_train_prediction) in [:in_transit_to, :incoming_at] and
         next_train_prediction
         |> Prediction.stop_for_vehicle()
         |> common_params.fetch_parent_stop_id_fn.() ==
           common_params.train_crowding_config.station_id do
      _ = log_crowding_info(:in_transit, common_params)

      Agent.delete(
        common_params.train_crowding_config.station_id,
        common_params.train_crowding_config.direction_id
      )

      [
        %CrowdingWidget{
          screen: common_params[:screen_config],
          prediction: next_train_prediction,
          now: common_params[:now]
        }
      ]

      # Test other heuristics
    else
      log_heuristics(common_params)
    end
  end

  defp log_heuristics(common_params) do
    train_crowding_config = common_params.train_crowding_config
    next_train_prediction = common_params.next_train_prediction

    ol_stop_sequence =
      if train_crowding_config.direction_id == 0 do
        @ol_station_to_platform_map
      else
        Enum.reverse(@ol_station_to_platform_map)
      end

    previous_stop_index =
      Enum.find_index(
        ol_stop_sequence,
        &(elem(&1, 0) == train_crowding_config.station_id)
      ) - 1

    {_, platform_id_tuple} = Enum.at(ol_stop_sequence, previous_stop_index)

    previous_platform_id = elem(platform_id_tuple, train_crowding_config.direction_id)

    cached_prediction =
      Agent.get(train_crowding_config.station_id, train_crowding_config.direction_id)

    cond do
      cached_prediction != nil ->
        # Time-based heuristic
        # We think the train is about to leave the previous station. Log the heuristic.
        _ = check_time_based_heuristic(cached_prediction, common_params, -10)

        # Consecutive crowding class heuristic.
        # Crowding class this fetch is the same as last. Log the heuristic.
        _ =
          check_consecutive_crowding_heuristic(
            next_train_prediction,
            previous_platform_id,
            cached_prediction,
            common_params
          )

        []

      # Cache previous prediction but don't log the widget
      Prediction.vehicle_status(next_train_prediction) == :stopped_at and
          Prediction.stop_for_vehicle(next_train_prediction) == previous_platform_id ->
        previous_station_prediction_current_trip =
          fetch_previous_station_prediction(
            train_crowding_config,
            previous_platform_id,
            next_train_prediction.trip.id,
            common_params.fetch_predictions_fn
          )

        if is_nil(previous_station_prediction_current_trip) do
          Logger.warning(
            "[log_heuristics] Failed to fetch previous station's prediction: current_platform_id: #{train_crowding_config.station_id} previous_platform_id: #{previous_platform_id} trip_id: #{next_train_prediction.trip.id}"
          )

          []
        else
          # Cache the prediction for the current trip at the previous station.
          Agent.put(
            train_crowding_config.station_id,
            train_crowding_config.direction_id,
            previous_station_prediction_current_trip
          )

          []
        end

      true ->
        []
    end
  end

  defp fetch_previous_station_prediction(
         train_crowding_config,
         relevant_platform_id,
         trip_id,
         fetch_predictions_fn
       ) do
    params = %{
      direction_id: train_crowding_config.direction_id,
      route_ids: [train_crowding_config.route_id],
      stop_ids: [relevant_platform_id],
      trip_id: trip_id
    }

    {:ok, predictions} = fetch_predictions_fn.(params)
    List.first(predictions)
  end

  defp check_time_based_heuristic(
         cached_prediction,
         common_params,
         previous_departure_time_cushion
       ) do
    # cached_prediction.departure_time minus previous_departure_time_cushion is when we expect crowding to be reliable.
    # When now >= this time, log the widget.
    log_widget_after_time =
      DateTime.add(cached_prediction.departure_time, previous_departure_time_cushion)

    if DateTime.compare(
         common_params.now,
         log_widget_after_time
       ) in [
         :eq,
         :gt
       ] do
      log_crowding_info(
        :time_based,
        common_params
      )
    end
  end

  defp check_consecutive_crowding_heuristic(
         next_train_prediction,
         relevant_platform_id,
         cached_prediction,
         common_params
       ) do
    if next_train_prediction.vehicle.carriages ==
         cached_prediction.vehicle.carriages do
      log_crowding_info(
        :consecutive_crowding,
        common_params
      )
    else
      # Update the cached prediction so we can check the new crowding classes next fetch.
      # The departure time we use in the other heuristic should not change, and if it does it is changing to a more accurate time.
      # If the prediction is nil, leave the existing one alone just in case the time heuristic can log next refresh.
      previous_station_prediction_current_trip =
        fetch_previous_station_prediction(
          common_params.train_crowding_config,
          relevant_platform_id,
          next_train_prediction.trip.id,
          common_params.fetch_predictions_fn
        )

      if previous_station_prediction_current_trip != nil do
        Agent.put(
          common_params.train_crowding_config.station_id,
          common_params.train_crowding_config.direction_id,
          previous_station_prediction_current_trip
        )
      end
    end
  end

  # Given alerts at this station, check to see if any alert make this a temporary terminal
  defp any_alert_makes_this_a_terminal?(alerts, location_context, now) do
    Enum.any?(alerts, fn alert ->
      if Alert.happening_now?(alert, now) do
        temporary_terminal?(%{alert: alert, location_context: location_context})
      end
    end)
  end

  # credo:disable-for-next-line
  # TODO: This isn't the first time we've written a temporary_terminal function, but this one
  # is a little more reusable? Consider using this func in other places
  defp temporary_terminal?(localized_alert) do
    localized_alert.alert.effect in [:suspension, :shuttle] and
      LocalizedAlert.location(localized_alert) in [:boundary_downstream, :boundary_upstream]
  end

  defp log_crowding_info(
         scenario,
         %{
           next_train_prediction: prediction,
           train_crowding_config: train_crowding_config,
           logging_options: %{
             is_real_screen: true,
             screen_id: screen_id,
             triptych_pane: triptych_pane
           }
         } = common_params
       ) do
    Agent.delete(train_crowding_config.station_id, train_crowding_config.direction_id)

    crowding_levels =
      Enum.map_join(
        prediction.vehicle.carriages,
        ",",
        &Util.translate_carriage_occupancy_status/1
      )

    Logger.info(
      "[train_crowding car_crowding_info] screen_id=#{screen_id} triptych_pane=#{triptych_pane} trip_id=#{prediction.trip.id} car_crowding_levels=#{crowding_levels} scenario=#{scenario}"
    )

    Screens.OlCrowding.DynamicSupervisor.start_logger(crowding_levels, common_params)
  end

  defp log_crowding_info(_, _), do: :ok
end
