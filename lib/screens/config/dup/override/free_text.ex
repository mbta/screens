defmodule Screens.Config.Dup.Override.FreeText do
  @moduledoc false

  @type t ::
          String.t()
          | %{format: format, text: String.t()}
          | %{route: route_pill}
          | %{color: color, text: String.t()}
          | %{special: special}
          | %{icon: Screens.Config.Dup.Override.FreeTextLine.icon()}

  @type format :: :bold | :small
  @type route_pill ::
          :red
          | :blue
          | :orange
          | :green
          | :silver
          | :cr
          | :green_b
          | :green_c
          | :green_d
          | :green_e
  @type color :: :red | :blue | :orange | :green | :silver | :purple
  @type special :: :break

  def from_json(text) when is_binary(text) do
    text
  end

  for format <- ~w[bold small]a do
    format_string = Atom.to_string(format)

    def from_json(%{"format" => unquote(format_string), "text" => text}) do
      %{format: unquote(format), text: text}
    end
  end

  for route_pill <- ~w[red blue orange green silver cr green_b green_c green_d green_e]a do
    route_pill_string = Atom.to_string(route_pill)

    def from_json(%{"route" => unquote(route_pill_string)}) do
      %{route: unquote(route_pill)}
    end
  end

  for color <- ~w[red blue orange green silver purple]a do
    color_string = Atom.to_string(color)

    def from_json(%{"color" => unquote(color_string), "text" => text}) do
      %{color: unquote(color), text: text}
    end
  end

  for special <- ~w[break]a do
    special_string = Atom.to_string(special)

    def from_json(%{"special" => unquote(special_string)}) do
      %{special: unquote(special)}
    end
  end

  for icon <-
        ~w[warning x shuttle subway cr walk red blue orange green silver green_b green_c green_d green_e]a do
    icon_string = Atom.to_string(icon)

    def from_json(%{"icon" => unquote(icon_string)}) do
      %{icon: unquote(icon)}
    end
  end

  def to_json(value), do: value
end
