defmodule Screens.V2.Template do
  @moduledoc false

  import Screens.V2.Template.Guards

  @typedoc """
  A paging_index is used in combination with a slot_id to
  uniquely identify a paged element on the screen.
  """
  @type paging_index :: non_neg_integer()

  @typedoc """
  A non_paged_slot_id represents a defined, non-paged region on the screen.
  e.g. :header, :main_content, :flex_zone
  """
  @type non_paged_slot_id :: atom()

  @typedoc """
  A paged_slot_id uniquely identifies a paged element on the screen.
  e.g. {0, :medium_left}, {1, :large}
  """
  @type paged_slot_id :: {paging_index(), non_paged_slot_id()}

  @typedoc """
  A slot_id represents a defined region on the screen.
  e.g. :header, {0, :medium_left}
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
          paged_slot_id() | {paged_slot_id(), %{layout_type() => list(paged_template())}}
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
  @type template ::
          non_paged_slot_id()
          | paged_template()
          | {non_paged_slot_id(), %{layout_type() => list(template())}}

  @typedoc """
  A layout represents one possible way to resolve a template.
  e.g. a layout for the above flex zone could be:
  {[:medium_left, :medium_right],
   {:flex_zone, {:two_medium, [:medium_left, :medium_right]}}}
  """
  @type layout :: slot_id() | {slot_id(), {layout_type(), list(layout())}}

  @spec slot_combinations(template()) :: nonempty_list({nonempty_list(slot_id()), layout()})
  def slot_combinations(template) do
    template
    |> layout_combinations()
    |> Enum.map(fn layout -> {flatten_layout(layout), layout} end)
  end

  @spec layout_combinations(template()) :: nonempty_list(layout())
  def layout_combinations(template)
      when is_slot_id(template) do
    [template]
  end

  def layout_combinations({slot_id, layout_map}) do
    Enum.flat_map(layout_map, fn {layout_type, template_list} ->
      template_list
      |> Enum.map(&layout_combinations/1)
      |> product()
      |> Enum.map(fn list -> {slot_id, {layout_type, list}} end)
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
  defp flatten_layout(layout) when is_slot_id(layout) do
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

  def slots_match?(s1, s2) do
    depage_slot_id(s1) == depage_slot_id(s2)
  end

  def depage_slot_id({_page_index, slot_id}), do: slot_id
  def depage_slot_id(slot_id), do: slot_id

  @doc """
  Used for sorting. Non-paged slots precede all paged slots but are otherwise
  considered equal to each other for sorting purposes, to maintain the layout order as much as possible.
  Paged slots are ordered by their page indices only, again to maintain the layout order.
  """
  def slot_precedes_or_equal?(s1, s2)
      when is_paged_slot_id(s1) and is_non_paged_slot_id(s2) do
    false
  end

  def slot_precedes_or_equal?({page1, _} = s1, {page2, _} = s2)
      when is_paged_slot_id(s1) and is_paged_slot_id(s2) do
    page1 <= page2
  end

  def slot_precedes_or_equal?(_, _), do: true
end
