defmodule Screens.V2.Template do
  @moduledoc false

  @typedoc """
  Regions of screen content can be paged across data loads.
  Paging cannot be nested: one paged region cannot contain another.
  Use `with_paging/2` to create a paged region within a template.
  """
  @type paging_index :: non_neg_integer()

  @type non_paged_slot_id :: atom()
  @type paged_slot_id :: {paging_index(), slot_id()}
  @typedoc """
  A slot_id represents a defined region on the screen.
  e.g. :header, :main_content, :flex_zone, {0, :flex_zone}
  """
  @type slot_id :: non_paged_slot_id() | paged_slot_id()

  @typedoc """
  A layout_type represents a way of filling a defined region on the screen.
  In the API, this is the value of `type`.
  On the frontend, this corresponds to the React Component which will be used.
  e.g. :normal, :takeover, :two_medium
  """
  @type layout_type :: atom()

  @type non_paged_template ::
          non_paged_slot_id()
          | {non_paged_slot_id(), %{layout_type() => list(non_paged_template())}}
  @type paged_template ::
          paged_slot_id()
          | {paged_slot_id(), %{layout_type() => list(paged_template())}}
  @typedoc """
  A template represents all possible ways to fill a region on the screen.
  e.g. a Bus Shelter Screen Flex Zone could have the template:
  {:flex_zone,
   %{
     one_large: [:large],
     two_medium: [:medium_left, :medium_right],
     one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right]
   }}
  """
  @type template :: non_paged_template() | nonempty_list(paged_template())

  @typedoc """
  A layout represents one possible way to resolve a template.
  e.g. a layout for the above flex zone could be:
  {[:medium_left, :medium_right],
   {:flex_zone, {:two_medium, [:medium_left, :medium_right]}}}
  """
  @type layout :: slot_id() | {slot_id(), {layout_type(), list(layout())}}

  @spec with_paging(non_paged_template(), pos_integer()) :: list(template())
  def with_paging(template, num_pages) when is_atom(template) or is_atom(elem(template, 0)) do
    Enum.map(0..(num_pages - 1), &paged_template(template, &1))
  end

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

  def layout_combinations({slot_id, template}) do
    Enum.flat_map(template, fn {layout, template_list} ->
      template_list
      |> Enum.map(&layout_combinations/1)
      |> product()
      |> Enum.map(fn list -> {slot_id, {layout, list}} end)
    end)
  end

  defp paged_template(template, page_index) when is_atom(template) do
    paged_id(template, page_index)
  end

  defp paged_template({slot_id, template}, page_index) when is_atom(slot_id) do
    {paged_id(slot_id, page_index), paged_layout_map(template, page_index)}
  end

  defp paged_id(slot_id, page_index) do
    {page_index, slot_id}
  end

  defp paged_layout_map(layout_map, page_index) do
    layout_map
    |> Enum.map(fn {layout_type, child_templates} ->
      {layout_type, Enum.map(child_templates, &paged_template(&1, page_index))}
    end)
    |> Enum.into(%{})
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
      {slot_id(layout), position_widget_instances(layout, selected_widget_map)}
    end)
    |> Enum.into(%{type: layout_type})
  end

  @spec slot_id(layout()) :: slot_id()
  defp slot_id(layout) when is_atom(layout), do: layout
  defp slot_id({slot_id, {_layout_type, _layout_list}}), do: slot_id
end
