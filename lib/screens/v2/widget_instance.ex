defprotocol Screens.V2.WidgetInstance do
  @type priority :: nonempty_list(non_neg_integer)
  @type slot_id :: atom()
  @type widget_type :: atom()

  @typedoc """
  Widget functions can return this value to signal that some condition was found making the WidgetInstance
  ineligible for placement on the screen. We usually check for this value in `valid_candidate?/1`.
  """
  @type no_render :: :no_render

  @doc """
  Returns the widget's priority. A priority is encoded as a nonempty list of non-negative integers. For example:

  ```
  [1]

  [0]

  [1, 1, 2]
  ```

  The main purpose of priority values is to act as a sort key for each widget. We take advantage
  of Elixir's default term ordering for lists, which compares each element in order until a non-equal pair is found.

  ```
  true = [0] < [1]

  false = [2] < [1]

  # The first non-equal pair decides the result. In this case, 2 < 25.
  true = [1, 2, 99] < [1, 25, 0]

  true = [2, 0] < [3]

  # when one list ends without a tiebreaker, the shorter list wins
  true = [1, 2] < [1, 2, 0]
  ```

  This allows priority values to be as rough-or-fine-grained as we need them to be.

  The highest possible priority is `[0]`.
  """
  @spec priority(t) :: priority() | no_render()
  def priority(instance)

  @doc """
  Returns a JSON-serialization-friendly map of the widget's data, intended for the client.
  """
  @spec serialize(t) :: map()
  def serialize(instance)

  @doc """
  Returns a list of slot IDs that the widget can be placed in.

  If the framework is able to fit it into more than one valid slot, the earlier one in the returned list wins.
  """
  @spec slot_names(t) :: list(slot_id) | no_render()
  def slot_names(instance)

  @doc """
  A unique name for the widget, used by the client to render the widget's data with the appropriate React component.
  """
  @spec widget_type(t) :: widget_type() | no_render()
  def widget_type(instance)

  @doc """
  Indicates whether the widget is valid for display.

  Usually this always returns true, but for widgets with complicated logic, a reason to take it out of the running
  may become known after its initial creation in the candidate generator.
  """
  @spec valid_candidate?(t) :: boolean()
  def valid_candidate?(instance)

  @doc """
  Returns a map of the widget's data, intended for consumption by the widget's audio view. (`audio_view/1`)
  """
  @spec audio_serialize(t) :: map()
  def audio_serialize(instance)

  @doc """
  Returns a priority value used to sort the widget among others being rendered to SSML.
  """
  @spec audio_sort_key(t) :: priority()
  def audio_sort_key(instance)

  @doc """
  Indicates whether the widget is valid for inclusion in the audio readout.
  """
  @spec audio_valid_candidate?(t) :: boolean()
  def audio_valid_candidate?(instance)

  @doc """
  Returns the view module responsible for rendering this widget's data to SSML for speech synthesis.
  """
  @spec audio_view(t) :: module()
  def audio_view(instance)
end
