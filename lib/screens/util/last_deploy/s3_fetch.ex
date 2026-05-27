defmodule Screens.Util.LastDeploy.S3Fetch do
  @moduledoc false

  alias Screens.Report

  @bucket "mbta-screens"
  @object "LAST_DEPLOY"

  @rfc2822 "{WDshort}, {D} {Mshort} {YYYY} {h24}:{m}:{s} {Zname}"

  def get_last_deploy_time do
    env = Application.get_env(:screens, :environment_name, "screens-prod")
    operation = ExAws.S3.get_object(@bucket, "#{env}/#{@object}")

    with {:request, {:ok, %{headers: headers}}} <- {:request, ExAws.request(operation)},
         {:header, {:ok, value}} <- {:header, headers |> Map.new() |> Map.fetch("last-modified")},
         {:parse, {:ok, %DateTime{} = datetime}} <- {:parse, Timex.parse(value, @rfc2822)} do
      datetime
    else
      {stage, error} ->
        Report.error("last_deploy_fetch_failed", stage: stage, error: inspect(error))
        nil
    end
  end
end
