defmodule Screens.V2.Template do
  @moduledoc false

  @type layout_key :: atom()
  @type slot_id :: atom()
  @type template :: slot_id() | %{layout_key() => list(template())}
  @type layout :: slot_id() | {layout_key(), list(layout())}

  @spec slot_combinations(template()) :: nonempty_list({nonempty_list(slot_id()), layout()})
  def slot_combinations(template) do
    template
    |> layout_combinations()
    |> Enum.map(fn layout -> {flatten_layout(layout), layout} end)
  end

  @spec layout_combinations(template()) :: nonempty_list(layout())
  def layout_combinations(template) when is_atom(template) do
    [template]
  end

  def layout_combinations(template) when is_map(template) do
    Enum.flat_map(template, fn {layout, template_list} ->
      template_list
      |> Enum.map(&layout_combinations/1)
      |> product()
      |> Enum.map(fn list -> {layout, list} end)
    end)
  end

  @spec product(list(list(layout()))) :: list(layout())
  def product(list_of_lists) do
    Enum.reduce(list_of_lists, [[]], fn list, acc ->
      for l <- list, a <- acc do
        a ++ [l]
      end
    end)
  end

  @spec flatten_layout(layout()) :: list(slot_id())
  def flatten_layout(layout) when is_atom(layout) do
    [layout]
  end

  def flatten_layout({_layout_key, layout_list}) do
    Enum.flat_map(layout_list, &flatten_layout/1)
  end
end
