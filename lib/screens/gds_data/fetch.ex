defmodule Screens.GdsData.Fetch do
  @moduledoc false

  import SweetXml
  use Timex
  require Logger

  @token_url_base "http://91.241.86.224/DMSService.asmx/GetToken"
  @device_list_url_base "http://91.241.86.224/DMSService.asmx/GetDevicesList"
  @ping_url_base "http://91.241.86.224/DMSService.asmx/GetDevicesPing"

  @screen_sn_list [
    "100301",
    "100303",
    "100311",
    "100105",
    "100313",
    "100315",
    "100319",
    "100302",
    "100317",
    "100316",
    "100304",
    "100322",
    "100323",
    "100305",
    "100306",
    "100309",
    "100308",
    "100310",
    "100101",
    "100098",
    "100102",
    "100097"
  ]

  def fetch_data_for_current_day do
    # GDS API Dates are in Central European time
    utc_time = DateTime.utc_now()
    {:ok, italy_time} = DateTime.shift_zone(utc_time, "Europe/Rome")
    italy_date = DateTime.to_date(italy_time)

    case get_token() do
      {:ok, token} ->
        devices_data = fetch_devices_data(token, italy_date)
        pings_data = fetch_pings_data(token, italy_date)
        merge_device_and_ping_data(devices_data, pings_data)

      :error ->
        _ = Logger.info("gds_fetch_error get_token")
        :error
    end
  end

  defp get_token(num_retries \\ 2) do
    case {do_get_token(), num_retries} do
      {:error, 0} -> :error
      {:error, _} -> get_token(num_retries - 1)
      {{:ok, token}, _} -> {:ok, token}
    end
  end

  defp do_get_token do
    params = %{
      "UserName" => Application.get_env(:screens, :gds_dms_username),
      "Password" => Application.get_env(:screens, :gds_dms_password),
      "Company" => "M B T A"
    }

    @token_url_base
    |> build_url(params)
    |> make_and_parse_request(&parse_token/1)
  end

  defp parse_token(xml) do
    token =
      xml
      |> xpath(~x"//string/text()")
      |> xpath(~x"//Token/text()"s)

    {:ok, token}
  end

  defp fetch_devices_data(token, date) do
    params = %{
      "Token" => token,
      "Year" => date.year,
      "Month" => date.month,
      "Day" => date.day
    }

    url = build_url(@device_list_url_base, params)
    make_and_parse_request(url, &parse_devices_data/1)
  end

  defp parse_devices_data(xml) do
    %{logs: logs} =
      xml
      |> xpath(~x"//string/text()")
      |> xmap(
        logs: [
          ~x"//Devices/Device"l,
          name: ~x"./name/text()"s,
          battery: ~x"./battery/text()"s,
          temp: ~x"./temp_internal/text()"s,
          humidity: ~x"./humidity/text()"s,
          call: ~x"./LastCall/text()"s,
          sn: ~x"./sn/text()"s
        ]
      )

    devices_data =
      logs
      |> Enum.map(&parse_device_log/1)
      |> Enum.into(%{})

    {:ok, devices_data}
  end

  defp parse_device_log(%{
         battery: battery_str,
         call: call_str,
         humidity: humidity_str,
         name: screen_name,
         sn: screen_sn,
         temp: temp_str
       }) do
    {screen_sn,
     %{
       battery: parse_european_decimal(battery_str),
       humidity: parse_european_decimal(humidity_str),
       temperature: parse_european_decimal(temp_str),
       log_time: parse_european_datetime(call_str),
       screen_name: screen_name,
       time: DateTime.utc_now()
     }}
  end

  defp parse_european_decimal(s) do
    [integer, decimal] = String.split(s, ",", parts: 2)
    String.to_integer(integer) + String.to_float("0." <> decimal)
  end

  defp parse_european_datetime(s) do
    with {:ok, naive_datetime} <- Timex.parse(s, "%d/%m/%Y %H:%M:%S", :strftime),
         {:ok, dt} <- DateTime.from_naive(naive_datetime, "Europe/Rome"),
         {:ok, utc_dt} <- DateTime.shift_zone(dt, "Etc/UTC") do
      utc_dt
    else
      _ -> nil
    end
  end

  defp fetch_pings_data(token, date) do
    pings_data =
      @screen_sn_list
      |> Enum.map(&fetch_ping_data(token, &1, date))
      |> Enum.into(%{})

    {:ok, pings_data}
  end

  defp fetch_ping_data(token, screen_sn, date) do
    params = %{
      "Token" => token,
      "Sn" => screen_sn,
      "Year" => date.year,
      "Month" => date.month,
      "Day" => date.day
    }

    ping_data =
      @ping_url_base
      |> build_url(params)
      |> make_and_parse_request(&parse_ping/1)

    case ping_data do
      {:ok, ping_count} -> {screen_sn, ping_count}
      :error -> {screen_sn, nil}
    end
  end

  defp parse_ping(xml) do
    parsed =
      xml
      |> xpath(~x"//string/text()")
      |> xmap(calls: [~x"//Calls/Call"l, ping_count: ~x"./Call/text()"i])

    case parsed do
      %{calls: [%{ping_count: ping_count}]} -> {:ok, ping_count}
      _ -> :error
    end
  end

  defp merge_device_and_ping_data({:ok, devices_data}, {:ok, pings_data}) do
    merged_data =
      @screen_sn_list
      |> Enum.map(fn sn ->
        ping_count = Map.get(pings_data, sn)

        devices_data
        |> Map.get(sn)
        |> Map.put(:ping_count, ping_count)
      end)

    {:ok, merged_data}
  end

  defp merge_device_and_ping_data(_, _) do
    :error
  end

  defp build_url(base_url, params) when map_size(params) == 0 do
    base_url
  end

  defp build_url(base_url, params) do
    "#{base_url}?#{URI.encode_query(params)}"
  end

  defp make_and_parse_request(url, parse_fn) do
    with {:ok, response} <- HTTPoison.get(url),
         %{status_code: 200, body: body} <- response,
         {:ok, parsed} <- parse_fn.(body) do
      {:ok, parsed}
    else
      _ -> :error
    end
  end
end
