defprotocol Screens.V2.WidgetInstance do
  @type priority :: nonempty_list(integer)
  @type slot_id :: atom()
  @type widget_type :: atom()

  @typedoc """
  Widget functions can return this value to signal that some condition was found making the WidgetInstance
  ineligible for placement on the screen. We usually check for this value in `valid_candidate?/1`.
  """
  @type no_render :: :no_render

  @spec priority(t) :: priority() | no_render()
  def priority(instance)

  @spec serialize(t) :: map()
  def serialize(instance)

  @spec slot_names(t) :: list(slot_id) | no_render()
  def slot_names(instance)

  @spec widget_type(t) :: widget_type() | no_render()
  def widget_type(instance)

  @spec valid_candidate?(t) :: boolean()
  def valid_candidate?(instance)

  @spec audio_serialize(t) :: map()
  def audio_serialize(instance)

  @spec audio_sort_key(t) :: integer()
  def audio_sort_key(instance)

  @spec audio_valid_candidate?(t) :: boolean()
  def audio_valid_candidate?(instance)

  @spec audio_view(t) :: module()
  def audio_view(instance)
end
