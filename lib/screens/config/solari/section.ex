defmodule Screens.Config.Solari.Section do
  alias Screens.Config.Solari.Section.{Audio, Layout, Query}

  @type t :: %__MODULE__{
          name: String.t(),
          arrow: :n | :e | :s | :w | :ne | :se | :sw | :nw | nil,
          query: Query.t(),
          layout: Layout.t(),
          audio: Audio.t(),
          pill: :bus | :red | :orange | :green | :blue | :cr | :mattapan | :silver
        }

  @default_name ""
  @default_arrow nil
  @default_pill :bus

  defstruct name: @default_name,
            arrow: @default_arrow,
            query: Query.from_json(:default),
            layout: Layout.from_json(:default),
            audio: Audio.from_json(:default),
            pill: @default_pill

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    name = Map.get(json, "name", :default)
    arrow = Map.get(json, "arrow", :default)
    query = Map.get(json, "query", :default)
    layout = Map.get(json, "layout", :default)
    audio = Map.get(json, "audio", :default)
    pill = Map.get(json, "pill", :default)

    %__MODULE__{
      name: name_from_json(name),
      arrow: arrow_from_json(arrow),
      query: Query.from_json(query),
      layout: Layout.from_json(layout),
      audio: Audio.from_json(audio),
      pill: pill_from_json(pill)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{
        name: name,
        arrow: arrow,
        query: query,
        layout: layout,
        audio: audio,
        pill: pill
      }) do
    %{
      "name" => name,
      "arrow" => arrow_to_json(arrow),
      "query" => Query.to_json(query),
      "layout" => Layout.to_json(layout),
      "audio" => Audio.to_json(audio),
      "pill" => pill_to_json(pill)
    }
  end

  defp name_from_json(name) when is_binary(name) do
    name
  end

  defp name_from_json(_) do
    @default_name
  end

  for arrow <- ~w[n e s w ne se sw nw]a do
    arrow_string = Atom.to_string(arrow)

    defp arrow_from_json(unquote(arrow_string)) do
      unquote(arrow)
    end

    defp arrow_to_json(unquote(arrow)) do
      unquote(arrow_string)
    end
  end

  defp arrow_from_json(_) do
    @default_arrow
  end

  for pill <- ~w[bus red orange green blue cr mattapan silver]a do
    pill_string = Atom.to_string(pill)

    defp pill_from_json(unquote(pill_string)) do
      unquote(pill)
    end

    defp pill_to_json(unquote(pill)) do
      unquote(pill_string)
    end
  end

  defp pill_from_json(_) do
    @default_pill
  end
end
