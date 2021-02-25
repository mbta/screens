defmodule Screens.V2.Template do
  @moduledoc false

  @type layout_type :: atom()
  @type slot_id :: atom()
  @type template :: slot_id() | {slot_id(), %{layout_type() => list(template())}}
  @type layout :: slot_id() | {slot_id(), {layout_type(), list(layout())}}

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

  def layout_combinations({foo, template}) do
    Enum.flat_map(template, fn {layout, template_list} ->
      template_list
      |> Enum.map(&layout_combinations/1)
      |> product()
      |> Enum.map(fn list -> {foo, {layout, list}} end)
    end)
  end

  @spec product(list(list(layout()))) :: list(layout())
  defp product(list_of_lists) do
    Enum.reduce(list_of_lists, [[]], fn list, acc ->
      for l <- list, a <- acc do
        a ++ [l]
      end
    end)
  end

  @spec flatten_layout(layout()) :: list(slot_id())
  defp flatten_layout(layout) when is_atom(layout) do
    [layout]
  end

  defp flatten_layout({_, {_, layout_list}}) do
    Enum.flat_map(layout_list, &flatten_layout/1)
  end

  @spec position_widget_instances(layout(), map()) :: map()
  def position_widget_instances(layout, selected_widget_map) when is_atom(layout) do
    Map.get(selected_widget_map, layout)
  end

  def position_widget_instances({_slot_id, {layout_type, layout_list}}, selected_widget_map) do
    layout_list
    |> Enum.map(fn layout ->
      {layout_name(layout), position_widget_instances(layout, selected_widget_map)}
    end)
    |> Enum.into(%{type: layout_type})
  end

  @spec layout_name(layout()) :: atom()
  defp layout_name(layout) when is_atom(layout), do: layout
  defp layout_name({slot_id, {_layout_type, _layout_list}}), do: slot_id
end
