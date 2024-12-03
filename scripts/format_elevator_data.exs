#!/usr/bin/env -S ERL_FLAGS=+B elixir

# Script used to format the spreadsheet found at
# https://docs.google.com/spreadsheets/d/1lHogme-2SuDSgjrRK52k7yVgSFK-v_LMmUfkYgBJjIU/edit?gid=179933470#gid=179933470

# To use this script:
# 1. Download the spreadsheet above
# 2. Rename downloaded file to `elevator_station_data.csv` and place in priv/elevators/
# 3. Run `elixir scripts/format_elevator_data.exs

Mix.install([{:jason, "~> 1.4"}, {:csv, "~> 3.2"}])

formatted_data =
  File.stream!("priv/elevators/elevator_station_data.csv")
  |> CSV.decode(headers: true)
  |> Enum.map(fn
    {:ok, %{"elevator_id" => ""}} ->
      nil

    {:ok,
     %{
       "elevator_id" => id,
       "Exiting System Categorization" => category,
       "parent_station" => station_id
     }} ->
      %{id: id, station_id: station_id, nearby_redundancy?: category == "1 - Nearby"}
  end)
  |> Enum.reject(&is_nil/1)

File.write("priv/elevators/elevator_redundancy_data.json", Jason.encode!(formatted_data, pretty: true))
