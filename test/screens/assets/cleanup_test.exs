defmodule Screens.Assets.CleanupTest do
  use ExUnit.Case, async: true

  alias Screens.Assets.Cleanup
  alias Screens.Config.ScreenConfig

  @now ~U[2026-10-22 12:00:00Z]
  @old "2026-09-20T12:00:00.000Z"

  defp environment, do: Application.fetch_env!(:screens, :environment_name)
  defp key(path), do: "#{environment()}/#{path}"
  defp object(path, modified \\ @old), do: %{key: key(path), last_modified: modified}

  defp listing(objects, extra \\ %{}) do
    {:ok, %{body: Map.merge(%{contents: objects, is_truncated: "false"}, extra)}}
  end

  defp request_for(objects) do
    fn operation ->
      assert operation.http_method == :get
      assert operation.bucket == "mbta-screens"
      prefix = operation.params["prefix"]
      listing(Enum.filter(objects, &String.starts_with?(&1.key, prefix)))
    end
  end

  test "retains references anywhere in config, including disabled screens and absolute URLs" do
    paths =
      ~w[images/evergreen.png images/map.png images/header.png images/future.png videos/future.mp4]

    configs = [
      %ScreenConfig{
        config: %{
          disabled: true,
          app_params: %{
            evergreen_content: [%{asset_path: "images/evergreen.png"}],
            full_line_map: [%{asset_path: "images/map.png"}],
            departures: %{
              sections: [%{header: %{wayfinding_information: %{image_path: "images/header.png"}}}]
            },
            future_image_widget: %{
              image_path: "images/future.png",
              video_path: "videos/future.mp4"
            },
            future_url_widget: %{
              url:
                "https://mbta-screens.s3.amazonaws.com/#{environment()}/images/encoded%20name.png?version=1"
            }
          }
        }
      }
    ]

    objects = Enum.map(paths ++ ["images/encoded name.png", "images/unused.png"], &object/1)

    assert {:ok, [unused]} = Cleanup.preview(configs, [request: request_for(objects)], @now)
    assert unused == key("images/unused.png")
  end

  test "only old objects in media directories are eligible, never reusable subfolders or markers" do
    objects = [
      object("images/unused.png"),
      object("videos/unused.mp4"),
      object("images/reusable/future.png"),
      object("videos/reusable/future.mp4"),
      object("images/evergreen/old-prefix.png"),
      object("images/"),
      object("images/nested/"),
      object("images/recent.png", "2026-10-21T12:00:00Z"),
      object("images/boundary.png", "2026-09-22T12:00:00Z"),
      object("images/future.png", "2026-10-23T12:00:00Z"),
      object("images/unknown.png", "not a timestamp"),
      %{key: key("images/no-timestamp.png")},
      object("other/unused.png"),
      object("LAST_DEPLOY"),
      %{key: "another-environment/images/unused.png", last_modified: @old}
    ]

    request = fn operation ->
      # Even unexpected out-of-scope objects in an S3 response must not be deleted.
      assert operation.bucket == "mbta-screens"
      listing(objects)
    end

    assert Cleanup.preview([], [request: request], @now) ==
             {:ok,
              Enum.map(
                ~w[images/evergreen/old-prefix.png images/unused.png videos/unused.mp4],
                &key/1
              )}
  end

  test "reads all pages with continuation tokens" do
    images_prefix = "#{environment()}/images/"

    request = fn operation ->
      case {operation.params["prefix"], operation.params["continuation-token"]} do
        {^images_prefix, nil} ->
          listing([object("images/first.png")], %{
            is_truncated: "true",
            next_continuation_token: "next"
          })

        {_prefix, "next"} ->
          listing([object("images/second.png")])

        _ ->
          listing([])
      end
    end

    assert Cleanup.preview([], [request: request], @now) ==
             {:ok, [key("images/first.png"), key("images/second.png")]}
  end

  test "listing errors and invalid pagination fail closed" do
    assert {:error, {:asset_listing_failed, _, {:error, :unavailable}}} =
             Cleanup.preview([], [request: fn _ -> {:error, :unavailable} end], @now)

    assert {:error, :missing_continuation_token} =
             Cleanup.preview(
               [],
               [request: fn _ -> listing([], %{is_truncated: "true"}) end],
               @now
             )
  end

  test "deletion rechecks references and modification times and only removes confirmed keys" do
    configs = [%ScreenConfig{config: %{asset_path: "images/new-reference.png"}}]

    objects = [
      object("images/delete.png"),
      object("images/not-confirmed.png"),
      object("images/new-reference.png"),
      object("images/replaced.png", "2026-10-22T11:00:00Z"),
      object("images/reusable/keep.png")
    ]

    request = fn operation ->
      case operation.http_method do
        :get ->
          request_for(objects).(operation)

        :delete ->
          assert operation.path == key("images/delete.png")
          send(self(), :deleted)
          {:ok, %{status_code: 204}}
      end
    end

    confirmed = Enum.map(objects, & &1.key) -- [key("images/not-confirmed.png")]
    confirmed = confirmed ++ ["another-environment/images/delete.png", key("LAST_DEPLOY")]
    assert Cleanup.delete(configs, confirmed, [request: request], @now) == {:ok, 1}
    assert_received :deleted
    refute_received :deleted
  end

  test "no deletions happen if a later listing fails" do
    request = fn operation ->
      assert operation.http_method == :get

      if operation.params["prefix"] == "#{environment()}/videos/" do
        {:error, :unavailable}
      else
        request_for([object("images/delete.png")]).(operation)
      end
    end

    assert {:error, {:asset_listing_failed, _, _}} =
             Cleanup.delete([], [key("images/delete.png")], [request: request], @now)
  end

  test "stops on deletion failure and reports the number already deleted" do
    objects = [object("images/a.png"), object("images/b.png"), object("images/c.png")]
    first_path = key("images/a.png")
    second_path = key("images/b.png")

    request = fn operation ->
      case operation.http_method do
        :get ->
          request_for(objects).(operation)

        :delete ->
          case operation.path do
            ^first_path -> {:ok, %{status_code: 204}}
            ^second_path -> {:error, :forbidden}
          end
      end
    end

    assert Cleanup.delete([], Enum.map(objects, & &1.key), [request: request], @now) ==
             {:error, {:asset_delete_failed, key("images/b.png"), {:error, :forbidden}, 1}}
  end
end
