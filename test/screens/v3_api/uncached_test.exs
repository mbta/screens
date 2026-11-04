defmodule Screens.V3Api.UncachedTest do
  use ExUnit.Case, async: false

  alias Screens.V3Api
  alias Screens.V3Api.Cache

  setup do
    previous = Application.get_env(:screens, :api_v3_url)
    Application.put_env(:screens, :api_v3_url, "https://example.com/")
    on_exit(fn -> Application.put_env(:screens, :api_v3_url, previous) end)
  end

  test "fetches through the HTTP client without retaining a raw response" do
    params = %{"unique" => inspect(make_ref())}

    request = fn url, opts ->
      assert String.starts_with?(url, "https://example.com/schedules?")
      assert opts[:finch] == [name: V3Api.Finch]

      {:ok,
       %Req.Response{
         status: 200,
         body: %{"data" => []},
         headers: %{"last-modified" => ["modified"]}
       }}
    end

    assert {:ok, %{"data" => []}, "modified"} =
             V3Api.get_json_uncached("schedules", params, nil, request)

    assert Cache.get({"schedules", params}) == nil
  end

  test "revalidates using the dataset validator without needing the old response body" do
    request = fn _, opts ->
      assert {"if-modified-since", "modified"} in opts[:headers]
      {:ok, %Req.Response{status: 304}}
    end

    assert :not_modified = V3Api.get_json_uncached("schedules", %{}, "modified", request)

    assert {:error, {:http_status, 304}} =
             V3Api.get_json_uncached("schedules", %{}, nil, fn _, _ ->
               {:ok, %Req.Response{status: 304}}
             end)
  end

  test "handles missing validators and unsuccessful responses" do
    assert {:ok, %{}, nil} =
             V3Api.get_json_uncached("schedules", %{}, nil, fn _, _ ->
               {:ok, %Req.Response{status: 200, body: %{}, headers: %{}}}
             end)

    assert {:error, {:http_status, 503}} =
             V3Api.get_json_uncached("schedules", %{}, nil, fn _, _ ->
               {:ok, %Req.Response{status: 503}}
             end)

    assert {:error, :unavailable} =
             V3Api.get_json_uncached("schedules", %{}, nil, fn _, _ -> {:error, :unavailable} end)
  end
end
