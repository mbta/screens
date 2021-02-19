defprotocol Screens.V2.WidgetInstance do
  @type priority :: list(integer)
  @type slot_id :: atom()

  @spec priority(t) :: priority()
  def priority(instance)

  @spec serialize(t) :: map()
  def serialize(instance)

  @spec slot_names(t) :: list(slot_id)
  def slot_names(instance)
end
