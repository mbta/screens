defmodule Screens.GdsData.Fetch do
  @moduledoc false

  import SweetXml
  use Timex

  @token_url_base "http://91.241.86.224/DMSService.asmx/GetToken"
  @log_url_base "http://91.241.86.224/DMSService.asmx/GetLogCalls"
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

  @empty_log %{
    battery: nil,
    temperature: nil,
    humidity: nil,
    log_time: nil,
    screen_name: nil
  }

  def fetch_data_for_current_day do
    # GDS API Dates are in Central European time
    utc_time = DateTime.utc_now()
    {:ok, italy_time} = DateTime.shift_zone(utc_time, "Europe/Rome")
    italy_date = DateTime.to_date(italy_time)
    {:ok, token} = get_token()

    @screen_sn_list
    |> Enum.map(&fetch_screen_data(token, &1, italy_date))
  end

  def fetch_screen_data(token, screen_sn, date) do
    time = DateTime.utc_now()
    ping_count = fetch_ping_data(token, screen_sn, date)

    %{
      battery: battery,
      temperature: temperature,
      humidity: humidity,
      log_time: log_time,
      screen_name: screen_name
    } = fetch_log_data(token, screen_sn, date)

    %{
      time: time,
      screen_sn: screen_sn,
      screen_name: screen_name,
      ping_count: ping_count,
      battery: battery,
      temperature: temperature,
      humidity: humidity,
      log_time: log_time
    }
  end

  def fetch_ping_data(token, screen_sn, date) do
    params = %{
      "Token" => token,
      "Sn" => screen_sn,
      "Year" => date.year,
      "Month" => date.month,
      "Day" => date.day
    }

    url = build_url(@ping_url_base, params)

    with {:ok, response} <- HTTPoison.get(url),
         %{status_code: 200, body: body} <- response,
         parsed <- parse_ping(body) do
      parsed
    else
      _ -> nil
    end
  end

  def fetch_log_data(token, screen_sn, date) do
    params = %{
      "Token" => token,
      "Sn" => screen_sn,
      "Year" => date.year,
      "Month" => date.month,
      "Day" => date.day
    }

    url = build_url(@log_url_base, params)

    with {:ok, response} <- HTTPoison.get(url),
         %{status_code: 200, body: body} <- response,
         parsed <- parse_log(body) do
      parsed
    else
      _ -> @empty_log
    end
  end

  defp parse_european_decimal(s) do
    [integer, decimal] = String.split(s, ",", parts: 2)
    String.to_integer(integer) + String.to_float("0." <> decimal)
  end

  def parse_european_datetime(s) do
    with {:ok, naive_datetime} <- Timex.parse(s, "%d/%m/%Y %H:%M:%S", :strftime),
         {:ok, dt} <- DateTime.from_naive(naive_datetime, "Europe/Rome"),
         {:ok, utc_dt} <- DateTime.shift_zone(dt, "Etc/UTC") do
      utc_dt
    else
      _ -> nil
    end
  end

  def get_token(num_retries \\ 2) do
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

    url = build_url(@token_url_base, params)

    with {:ok, response} <- HTTPoison.get(url),
         %{status_code: 200, body: body} <- response,
         parsed <- parse_token(body) do
      {:ok, parsed}
    else
      _ -> :error
    end
  end

  defp parse_ping(xml) do
    parsed =
      xml
      |> xpath(~x"//string/text()")
      |> xmap(calls: [~x"//Calls/Call"l, ping_count: ~x"./Call/text()"i])

    case parsed do
      %{calls: [%{ping_count: ping_count}]} -> ping_count
      _ -> nil
    end
  end

  defp parse_log(xml) do
    %{logs: logs} =
      xml
      |> xpath(~x"//string/text()")
      |> xmap(
        logs: [
          ~x"//Logs/Log"l,
          battery: ~x"./battery/text()"s,
          temp: ~x"./temp_internal/text()"s,
          humidity: ~x"./humidity/text()"s,
          call: ~x"./Call/text()"s,
          name: ~x"./name/text()"s
        ]
      )

    case Enum.sort_by(logs, & &1.call, &>=/2) do
      [
        %{
          battery: battery_str,
          humidity: humidity_str,
          temp: temp_str,
          call: call_str,
          name: screen_name
        }
        | _
      ] ->
        %{
          battery: parse_european_decimal(battery_str),
          humidity: parse_european_decimal(humidity_str),
          temperature: parse_european_decimal(temp_str),
          log_time: parse_european_datetime(call_str),
          screen_name: screen_name
        }

      _ ->
        @empty_log
    end
  end

  defp parse_token(xml) do
    xml
    |> xpath(~x"//string/text()")
    |> xpath(~x"//Token/text()"s)
  end

  defp build_url(base_url, params) when map_size(params) == 0 do
    base_url
  end

  defp build_url(base_url, params) do
    "#{base_url}?#{URI.encode_query(params)}"
  end
end
