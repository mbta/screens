defmodule Screens.V2.CandidateGenerator.Widgets.BlueBikes do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.PreFare
  alias Screens.Config.V2.BlueBikes, as: BlueBikesConfig
  alias Screens.BlueBikes, as: BlueBikesData
  alias Screens.V2.WidgetInstance.BlueBikes, as: BlueBikesWidget

  def blue_bikes_instances(config, fetch_statuses_fn \\ &BlueBikesData.get_station_statuses/1)

  def blue_bikes_instances(
        %Screen{app_params: %app{blue_bikes: %BlueBikesConfig{enabled: true}}} = config,
        fetch_statuses_fn
      )
      when app in [PreFare] do
    station_ids = Enum.map(config.app_params.blue_bikes.stations, & &1.id)

    [%BlueBikesWidget{screen: config, station_statuses: fetch_statuses_fn.(station_ids)}]
  end

  def blue_bikes_instances(_, _), do: []
end
