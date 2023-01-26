defmodule Screens.Util.LastDeploy.S3Fetch do
  @moduledoc false

  @bucket "mbta-screens"

  def get_last_deploy_time do
    env = Application.get_env(:screens, :environment_name, "screens-prod")
    path = "/#{env}/LAST_DEPLOY"

    get_operation = ExAws.S3.get_object(@bucket, path)

    case ExAws.request(get_operation) do
      {:ok, %{headers: headers}} ->
        # Example format: Thu, 12 Jan 2023 17:38:08 GMT
        last_modified_string =
          headers
          |> Enum.into(%{})
          |> Map.get("Last-Modified")

        case Timex.parse(
               last_modified_string,
               "{WDshort}, {D} {Mshort} {YYYY} {h24}:{m}:{s} {Zname}"
             ) do
          {:ok, last_modified_dt} -> Timex.to_datetime(last_modified_dt)
          _ -> nil
        end

      {:error, _} ->
        nil
    end
  end
end
