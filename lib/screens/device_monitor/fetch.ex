defmodule Screens.DeviceMonitor.Fetch do
  @moduledoc "Shared data fetching logic for device monitor modules."

  @spec make_and_parse_request(
          url :: binary(),
          options :: keyword(),
          decode_fn :: (binary() -> {:ok, decoded} | {:error, term()}),
          vendor_name :: atom()
        ) :: {:ok, decoded} | :error
        when decoded: any()
  def make_and_parse_request(url, options, decode_fn, vendor_name) do
    with {:response, {:ok, %Req.Response{status: 200, body: body}}} <-
           {:response, Req.get(url, Keyword.put(options, :decode_body, false))},
         {:decode, {:ok, decoded}} <- {:decode, decode_fn.(body)} do
      {:ok, decoded}
    else
      {:response, {:ok, %Req.Response{status: status}}} ->
        log_fetch_error(vendor_name, :status_not_ok, url, status: status)

      {:response, {:error, e}} ->
        log_fetch_error(vendor_name, :fetch_error, url, exception: inspect(e))

      {:decode, _} ->
        log_fetch_error(vendor_name, :decode_error, url)

      _ ->
        log_fetch_error(vendor_name, :error, url)
    end
  end

  defp log_fetch_error(vendor_name, error, url, data \\ []) do
    Logster.warning(["#{vendor_name}_fetch_error", url: url, error: error] ++ data)
    :error
  end
end
