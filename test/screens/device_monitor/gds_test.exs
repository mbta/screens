defmodule Screens.DeviceMonitor.GdsTest do
  use ExUnit.Case, async: true

  alias Screens.DeviceMonitor.Gds
  alias SweetXml, as: Xml

  import SweetXml, only: [sigil_x: 2]

  @gds_xml File.read!("test/fixtures/gds_device_status.xml")

  describe "string_tag_inner_xml/1" do
    test "produces the same result as `xpath(\"//string/text()\")`" do
      expected = Xml.xpath(@gds_xml, ~x"//string/text()") |> to_string()
      actual = Gds.string_tag_inner_xml(@gds_xml)

      assert actual == expected
    end
  end
end
