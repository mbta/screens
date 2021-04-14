defmodule Screens.V2.Template.Guards do
  @moduledoc false

  defguardp is_paging_index(value)
            when is_integer(value) and value >= 0

  defguard is_non_paged_slot_id(value)
           when is_atom(value)

  defguard is_paged_slot_id(value)
           when is_paging_index(elem(value, 0)) and
                  is_non_paged_slot_id(elem(value, 1))

  defguard is_slot_id(value)
           when is_non_paged_slot_id(value) or
                  is_paged_slot_id(value)
end
