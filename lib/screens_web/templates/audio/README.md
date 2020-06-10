# Developing SSML Templates for Amazon Polly

While tweaking or adding to these templates, keep in mind that whitespace and newlines are _*not*_ ignored by Polly's SSML parser and will add unwanted pauses. I suggest the following:

- Temporarily disable your editor's setting to add a newline to the end of the file on save, or permanently disable it for `.ssml.eex` files if possible.
- Keep all non-rendering newlines within `<%= %>` or `<% %>` Elixir escape tags.
- Whenever you need to use a macro that uses the `do ... end` construct in a template, factor it out to a view function that returns a string or iodata, and call that function from the template. There is no way to avoid adding unnecessary newlines with inline macros in templates without making them unreadable.

  Bad (will result in unwanted pauses when synthesized):

  ```eex
  <%= case @route_id do %>
    <% "CR-" <> line_name -> %><%= line_name %> Commuter Rail train
    <% "Blue" -> %>Blue Line train
    <% "Red" -> %>Red Line train
    <% "Mattapan" -> %>Mattapan Trolley
    <% "Orange" -> %>Orange Line train
  <% end %>
  to <%= @destination %>
  ```

  Good:

  ```eex
  <%= render_route_id @route_id %> to <%= destination %>
  ```

  **Note**: If this function's return value contains any tags, they _must_ be wrapped in a `{:safe, _}` tuple to prevent the template engine from escaping the brackets. See `ScreensWeb.AudioView.say_as_address` for an example.

- Use `<s>` and `<p>` to explicitly mark sentences and paragraphs. Use `<break>` if you need to fine-tune a pause.
