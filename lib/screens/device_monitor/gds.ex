defmodule Screens.DeviceMonitor.Gds do
  @moduledoc false

  @behaviour Screens.DeviceMonitor.Vendor

  alias Screens.DeviceMonitor.Fetch
  alias SweetXml, as: Xml

  import SweetXml, only: [sigil_x: 2]

  @api_company_name "M B T A"
  @api_url_base "https://dmsmbta.gds.com/DMSService.asmx"
  @device_list_url_base "#{@api_url_base}/GetDevicesList"
  @token_url_base "#{@api_url_base}/GetToken"
  @vendor_name :gds

  @impl true
  def log({_from_dt, to_dt}) do
    Screens.DeviceMonitor.Logger.log_data(fn -> fetch(to_dt) end, :gds, "GDS_DMS_PASSWORD")
  end

  defp fetch(now) do
    with {:ok, token} <- get_token(),
         {:ok, devices_data} <- fetch_devices_data(token, now) do
      sns = Map.keys(devices_data)
      {:ok, merge_device_and_sn_data(sns, devices_data)}
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
      "UserName" => System.fetch_env!("GDS_DMS_USERNAME"),
      "Password" => System.fetch_env!("GDS_DMS_PASSWORD"),
      "Company" => @api_company_name,
      "AspxAutoDetectCookieSupport" => 1
    }

    @token_url_base
    |> build_url(params)
    |> Fetch.make_and_parse_request(&parse_token/1, @vendor_name)
  end

  defp parse_token(xml) do
    token = xml |> string_tag_inner_xml() |> Xml.xpath(~x"//Token/text()"s)
    {:ok, token}
  end

  defp fetch_devices_data(token, now) do
    # GDS API Dates are in Central European time
    {:ok, italy_time} = DateTime.shift_zone(now, "Europe/Rome")
    italy_date = DateTime.to_date(italy_time)

    params = %{
      "Token" => token,
      "Year" => italy_date.year,
      "Month" => italy_date.month,
      "Day" => italy_date.day,
      "AspxAutoDetectCookieSupport" => 1
    }

    @device_list_url_base
    |> build_url(params)
    |> Fetch.make_and_parse_request(&parse_devices_data(&1, now), @vendor_name)
  end

  defp parse_devices_data(xml, now) do
    %{logs: logs} =
      xml
      |> string_tag_inner_xml()
      |> Xml.xmap(
        logs: [
          ~x"//Devices/Device"l,
          name: ~x"./name/text()"s,
          battery: ~x"./battery/text()"s,
          temp: ~x"./temp_internal/text()"s,
          humidity: ~x"./humidity/text()"s,
          call: ~x"./LastCall/text()"s,
          sn: ~x"./sn/text()"s,
          ping_count: ~x"./Ping24/text()"s
        ]
      )

    {:ok, logs |> Enum.map(&parse_device_log(&1, now)) |> Enum.into(%{})}
  end

  # Gets content of the <string> tag and does basic character unescaping on it. This is orders of
  # magnitude faster than using SweetXml for this particular operation. (We don't need to handle
  # any of the extra special escape formats like &#...; or CDATA; they aren't used for this data.
  # If they ever start being used, xpath functions will fail on the improperly-unescaped XML and
  # we'll get alerted about missing logs.)
  def string_tag_inner_xml(xml) do
    ~r|<string xmlns="http://tempuri\.org/">(.*)</string>|
    |> Regex.run(xml, capture: :all_but_first)
    |> hd()
    |> String.replace(~w[&quot; &apos; &lt; &gt; &amp;], &unescape_special_char/1)
  end

  defp unescape_special_char("&quot;"), do: "\""
  defp unescape_special_char("&apos;"), do: "'"
  defp unescape_special_char("&lt;"), do: "<"
  defp unescape_special_char("&gt;"), do: ">"
  defp unescape_special_char("&amp;"), do: "&"

  defp parse_device_log(
         %{
           battery: battery_str,
           call: call_str,
           humidity: humidity_str,
           name: screen_name,
           sn: screen_sn,
           temp: temp_str,
           ping_count: ping_count
         },
         now
       ) do
    {screen_sn,
     %{
       battery: String.to_float(battery_str),
       humidity: String.to_float(humidity_str),
       temperature: String.to_float(temp_str),
       log_time: parse_datetime(call_str),
       screen_name: screen_name,
       time: now,
       ping_count: ping_count
     }}
  end

  defp parse_datetime(s) do
    with {:ok, naive_datetime} <- Timex.parse(s, "%-m/%-d/%Y %-I:%M:%S %p", :strftime),
         {:ok, dt} <- DateTime.from_naive(naive_datetime, "Europe/Rome"),
         {:ok, utc_dt} <- DateTime.shift_zone(dt, "Etc/UTC") do
      utc_dt
    else
      _ -> nil
    end
  end

  defp merge_device_and_sn_data(screen_sns, devices_data) do
    Enum.map(screen_sns, fn sn ->
      devices_data
      |> Map.get(sn)
      |> Map.put(:screen_sn, sn)
    end)
  end

  defp build_url(base_url, params) when map_size(params) == 0 do
    base_url
  end

  defp build_url(base_url, params) do
    "#{base_url}?#{URI.encode_query(params)}"
  end
end
