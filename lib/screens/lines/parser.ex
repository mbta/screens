defmodule Screens.Lines.Parser do
  @moduledoc false

  def parse_line(%{
        "id" => id,
        "attributes" => %{
          "long_name" => long_name,
          "short_name" => short_name,
          "sort_order" => sort_order
        }
      }) do
    %Screens.Lines.Line{
      id: id,
      long_name: long_name,
      short_name: short_name,
      sort_order: sort_order
    }
  end
end
