- Feature Name: `wayfinding_widget`
- Start Date: 2025-01-30
- RFC PR: [RFC: Wayfinding Widget](https://github.com/mbta/screens/pull/2845)
- Asana task: [Wayfinding Widget: Basic Functionality](https://app.asana.com/1/15492006741476/project/1185117109217422/task/1211428585696977)
- Status: Proposed

# Summary

We are adding more maps to CID screens, but they are currently using Evergreen Content as a means to render and display the images.
We would like a dedicated Wayfinding Widget with some special case handling across screens.

# Requirements

- Needs to be able to slot into the left side of Screens
- Needs to be able to be able to accommodate having Departures rendered above, below, or have Wayfinding take up the full screen
- Must be able to work with PreFare and Sectional screens
- Allow an optional sub-header similar to Departure.Section

# Proposal

## New Layout Types

New layout type for left side that is flexible in its CSS for us to handle custom Wayfinding widget height.
This flexibility would leverage some of the CSS flex handling in order to show the Wayfinding widget properly but then allow Departures to take the rest of the space.
A new type named `BodyLeftSplit` along with new slot names for use `body_left_top`, `body_left_bottom` would be added. New CSS would have to be written for these slots.

In the candidate generator `screen_template`, the new structure would look something like this:

```
{:body,
  %{
    body_normal: [
      {:body_left,
        %{
          body_left_normal: [:main_content_left],
          body_left_takeover: [:full_body_left],
          body_left_flex: Builder.with_paging(:paged_main_content_left, 4)
          body_left_split: [:body_left_top, :body_left_bottom]
        }},
      @body_right_layout,
    ],
    body_takeover: [:full_body_duo],
  }}

```

## ScreensConfig changes

- New Wayfinding widget module to configure `asset_url` for the Wayfinding image itself
- `placement` for assigning the Wayfinding widget to the top or bottom relative to the Departures widget
- `header_text` for the header text above the widget
- `text_for_audio` to describe the Wayfinding Image

The ScreenConfig values to pass through to use for CSS values would look like this:

```
%WayfindingItem{
  asset_url: String.t(),
  placement: :top | :bottom,
  header_text: Header.t() | nil,
  text_for_audio: String.t(),
}
```

which would eventually pass through to the Candidate Generator

```
%Wayfinding{
  screen: Screen.t(),
  asset_url: String.t(),
  placement: :top | :bottom,
  header_text: Header.t() | nil,
  text_for_audio: String.t(),
}
```

We will also have to create a new Widget `instance_fns` for Wayfinding. If Departures are configured, we use the `placement` field to place the Wayfinding widget in the appropriate upper/lower slot and the Departures widget in the other. If there are no Departures configured, we ignore the placement field and use the full screen slots for Wayfinding.

## Wayfinding.tsx

Finally, we'll have to create a component that maps the config to a Typescript component. Here is where we can reuse some work from previous image widgets (`EvergreenContent`, `FullLineMap`) but we'll have to handle the CSS accordingly to make sure the image is fitting appropriately.

# Questions

- Should we allow for custom image scaling at all? Would that make things unnecessarily complicated to configure? Would we ever want a Wayfinding widget to have empty space instead of having the image be in full size?
  - I'm inclined to say no due to potential complexity in configuration. I think it makes more sense to have the widget just provide one way of displaying and we can have the image be modified by Designers for any changes we need.
- How does the scaling work for Departures? If Departures has a flex size will it still be able to determine the number of departures to show?
  - Departures will truncate until it fits properly, so we don't have to worry about this.
- Should half height be a hardcoded option? Or should we always just take the Wayfinding image scale?
  - Unneeded if we have the image scaled, so we can leave this hardcoded value out too.

# Alternatives that I opted not to pursue

- Making Wayfinding Widget and Departures coupled so we didn't have to create new layout slots
  - I didn't quite want to couple the two widgets together as I'm thinking of them them as independent widgets, not a widget within a widget, although not necessarily opposed to this idea
- Modifying NormalBodyLeft/NormalBodyRight to be more flexible so we don't have excessive slots cause confusion
  - The hesitation here was due to the amount of refactoring that might come from that - seemed easier to add in this case than modify
