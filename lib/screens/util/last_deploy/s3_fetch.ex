defmodule Screens.Util.LastDeploy.S3Fetch do
  @moduledoc false

  alias Screens.Report

  @bucket "mbta-screens"
  @object "LAST_DEPLOY"

  def get_last_deploy_time do
    env = Application.get_env(:screens, :environment_name, "screens-prod")
    operation = ExAws.S3.get_object(@bucket, "#{env}/#{@object}")

    with {:request, {:ok, %{headers: headers}}} <- {:request, ExAws.request(operation)},
         {:header, {:ok, value}} <- {:header, headers |> Map.new() |> Map.fetch("last-modified")},
         # "Mon, 10 Aug 2026 15:11:37 GMT"
         {:parse, {:ok, %DateTime{} = datetime}} <-
           {:parse, Datix.DateTime.parse(value, "%a, %d %b %Y %H:%M:%S GMT")} do
      datetime
    else
      {stage, error} ->
        Report.error("last_deploy_fetch_failed", stage: stage, error: inspect(error))
        nil
    end
  end
end
