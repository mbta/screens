defmodule Screens.Lines.Parser do
  @moduledoc false

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "long_name" => long_name,
            "short_name" => short_name,
            "sort_order" => sort_order
          }
        },
        _included
      ) do
    %Screens.Lines.Line{
      id: id,
      long_name: long_name,
      short_name: short_name,
      sort_order: sort_order
    }
  end
end
