defmodule Screens.Config.Dup.Override do
  @moduledoc false

  alias Screens.Config.Dup.Override.{FullscreenAlert, PartialAlertList}

  @type screen0 :: PartialAlertList.t() | FullscreenAlert.t()
  @type screen1 :: FullscreenAlert.t()

  def screen0_from_json(%{"type" => "partial"} = json) do
    PartialAlertList.from_json(json)
  end

  def screen0_from_json(%{"type" => "fullscreen"} = json) do
    FullscreenAlert.from_json(json)
  end

  def screen1_from_json(%{"type" => "fullscreen"} = json) do
    FullscreenAlert.from_json(json)
  end

  def screen0_to_json(%PartialAlertList{} = screen0) do
    PartialAlertList.to_json(screen0)
  end

  def screen0_to_json(%FullscreenAlert{} = screen0) do
    FullscreenAlert.to_json(screen0)
  end

  def screen1_to_json(%FullscreenAlert{} = screen1) do
    FullscreenAlert.to_json(screen1)
  end
end
