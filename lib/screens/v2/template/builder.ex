defmodule Screens.V2.Template.Builder do
  @moduledoc "Utility functions for building screen templates."

  alias Screens.V2.Template
  import Screens.V2.Template.Guards

  @spec build_template(term()) :: Template.template()
  @doc """
  All draft templates should be passed through this function to produce
  a final valid template.
  """
  def build_template(draft_template) do
    flatten_paged_groups(draft_template)
  end

  @spec with_paging(Template.non_paged_template(), pos_integer()) ::
          nonempty_list(Template.paged_template())
  @doc """
  Adds paging to a template or part of a template.
  Input must not already be paged or contain any paged elements.
  """
  def with_paging(template, num_pages)
      when is_non_paged_slot_id(template)
      when is_non_paged_slot_id(elem(template, 0)) do
    Enum.map(0..(num_pages - 1), &paged_template(template, &1))
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

  defp flatten_paged_groups(draft_template)
       when is_slot_id(draft_template) do
    draft_template
  end

  defp flatten_paged_groups({slot_id, layout_map}) do
    layout_map =
      layout_map
      |> Enum.map(fn {k, children} -> {k, flatten_paged_groups(children)} end)
      |> Enum.into(%{})

    {slot_id, layout_map}
  end

  defp flatten_paged_groups(templates) when is_list(templates) do
    Enum.flat_map(templates, fn
      paged_group when is_list(paged_group) -> paged_group
      template -> [flatten_paged_groups(template)]
    end)
  end
end
