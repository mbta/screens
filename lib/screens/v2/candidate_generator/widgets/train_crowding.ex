defmodule Screens.V2.CandidateGenerator.Widgets.TrainCrowding do
  @moduledoc false

  require Logger

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{TrainCrowding, Triptych}
  alias Screens.OlCrowding.Agent
  alias Screens.Predictions.Prediction
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.TrainCrowding, as: CrowdingWidget

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
        any_alert_makes_this_a_terminal?(alerts, location_context),
        common_params
      )
    else
      :error -> []
    end
  end

  defp get_instance(
         alert_makes_this_a_terminal,
         common_params
       ) do
    next_train_prediction = common_params.next_train_prediction

    cond do
      is_nil(next_train_prediction) or
        alert_makes_this_a_terminal or
          next_train_prediction.vehicle.carriages == [] ->
        []

      # If there is an upcoming train, it's headed to this station, and we're not at a temporary terminal,
      # show the widget
      Prediction.vehicle_status(next_train_prediction) in [:in_transit_to, :incoming_at] and
          next_train_prediction
          |> Prediction.stop_for_vehicle()
          |> common_params.fetch_parent_stop_id_fn.() ==
            common_params.train_crowding_config.station_id ->
        log_crowding_info(:in_transit, common_params)

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
      true ->
        get_instance_using_dwell_time(common_params)
    end
  end

  defp get_instance_using_dwell_time(common_params) do
    train_crowding_config = common_params.train_crowding_config
    next_train_prediction = common_params.next_train_prediction

    previous_stop_index =
      Enum.find_index(
        @ol_station_to_platform_map,
        &(elem(&1, 0) == train_crowding_config.station_id)
      ) - 1

    {_, platform_id_tuple} = Enum.at(@ol_station_to_platform_map, previous_stop_index)

    relevant_platform_id = elem(platform_id_tuple, train_crowding_config.direction_id)

    time_of_last_prediction_plus_dwell =
      Agent.get(train_crowding_config.station_id, train_crowding_config.direction_id)

    cond do
      time_of_last_prediction_plus_dwell != nil ->
        # We think the train is about to leave the previous station. Show the widget.
        if DateTime.compare(common_params.now, time_of_last_prediction_plus_dwell) in [
             :eq,
             :gt
           ] do
          log_crowding_info(
            :dwell,
            common_params
          )

          [
            %CrowdingWidget{
              screen: common_params[:screen_config],
              prediction: next_train_prediction,
              now: common_params.now
            }
          ]
        else
          []
        end

      Prediction.vehicle_status(next_train_prediction) == :stopped_at and
          Prediction.stop_for_vehicle(next_train_prediction) == relevant_platform_id ->
        # Start timer for dwell time but don't show the widget
        params = %{
          direction_id: train_crowding_config.direction_id,
          route_ids: [train_crowding_config.route_id],
          stop_ids: [relevant_platform_id],
          trip_id: next_train_prediction.trip.id
        }

        {:ok, predictions} = common_params.fetch_predictions_fn.(params)
        previous_station_prediction_current_trip = List.first(predictions)

        if is_nil(previous_station_prediction_current_trip) do
          []
        else
          # The current trip's prediction for the previous station should have the times we need to predict dwell time.
          # Subtract 10 seconds to give us some cushion so we have a chance to show the widget before the train leaves.
          relevant_dwell_time =
            DateTime.diff(
              previous_station_prediction_current_trip.departure_time,
              previous_station_prediction_current_trip.arrival_time
            ) - 10

          now_plus_dwell = DateTime.add(common_params.now, relevant_dwell_time)
          IO.inspect(now_plus_dwell, label: "now_plus_dwell")

          Agent.put(
            train_crowding_config.station_id,
            train_crowding_config.direction_id,
            now_plus_dwell
          )

          []
        end

      true ->
        []
    end
  end

  # Given alerts at this station, check to see if any alert make this a temporary terminal
  defp any_alert_makes_this_a_terminal?(alerts, location_context) do
    Enum.any?(alerts, fn alert ->
      temporary_terminal?(%{alert: alert, location_context: location_context})
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
        &Util.translate_carriage_occupancy_status(&1.occupancy_status)
      )

    Logger.info(
      "[train_crowding car_crowding_info] screen_id=#{screen_id} triptych_pane=#{triptych_pane} trip_id=#{prediction.trip.id} car_crowding_levels=#{crowding_levels} scenario=#{scenario}"
    )

    _ = Screens.OlCrowding.DynamicSupervisor.start_logger(crowding_levels, common_params)
  end

  defp log_crowding_info(_, _), do: :ok
end
