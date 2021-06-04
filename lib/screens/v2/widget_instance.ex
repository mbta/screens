defprotocol Screens.V2.WidgetInstance do
  @type priority :: nonempty_list(integer)
  @type slot_id :: atom()
  @type widget_type :: atom()

  @spec priority(t) :: priority()
  def priority(instance)

  @spec serialize(t) :: map()
  def serialize(instance)

  @spec slot_names(t) :: list(slot_id)
  def slot_names(instance)

  @spec widget_type(t) :: widget_type()
  def widget_type(instance)
end
