- Feature Name: `dup_v2_alert_widget_backend`
- Start Date: 2023-01-30
- RFC PR: TBD
- Asana task: [[DUP v2] Plan backend for DUP alerts](https://app.asana.com/0/1185117109217413/1203830054341498/f)
- Status: Proposed

# Summary

[summary]: #summary

Our DUP app requires a unique approach to alerts and how they are displayed. DUPs contain one screen with three different pages (rotations). When an alert affecting the stops serving the DUP is active, each page displays the alert in a different way depending on how impactful the alert is to the screen.

[DUP alert spec](https://www.notion.so/mbta-downtown-crossing/DUP-Alert-Widget-Specification-a82acff850ed4f2eb98a04e5f3e0fe52)

# Motivation

[motivation]: #motivation

Converting the DUP app from v1 to v2 requires a different approach to alerts and how they are displayed on the screen.

# Guide-level explanation

[guide-level-explanation]: #guide-level-explanation

The DUP alerts widget needs to resolve a scenario specific to DUP screens: the screen "rotates" between three separate pages. When an applicable[^1] alert exists, each rotation has specific logic that determines which "type" of alert widget to display: `partial`[^2] or `takeover`[^3].

### CandidateGenerator

`CandidateGenerator.Dup` is responsible for deciding what alert should appear on a screen. It fetches all active alerts affecting the screen's `stop_ids` listed in each section of the `primary_departures` config, filters out all alerts that do not directly affect the current stop (no downstream alerts), and selects the alert with the highest priority[^4]. If an alert (or alerts if configured with two sections) meets all criteria, the `CandidateGenerator` will then create three `WidgetInstance`s for the alert(s) (one for each rotation).

### WidgetInstance

The DUP alert `WidgetInstance` is responsible for choosing alert type and serializing the alert data for the frontend to consume. The alert type will chosen based on rotation and how impactful the alert is.

# Reference-level explanation

[reference-level-explanation]: #reference-level-explanation

### CandidateGenerator

`CandidateGenerator.Dup` is responsible for fetching relevant alerts from the API. The API query will contain an `opts` array for each section:

```
opts = [
      stop_ids: <stop_ids from config>,
      route_ids: <route_ids from config>,
      route_types: ~w[light_rail subway]a
    ]
```

Each section will make a separate alerts fetch. With the two sets of results from these queries, we will apply a filter to eliminate alerts we do not want on screens: `Enum.filter(&relevant?/1)`. `relevant?/1` will return a list of active and applicable alerts[^1]. After we have a list (or lists if there are two sections) of alerts that are eligible for display, we choose the alert to display for each section based on a priority[^4]. The pipeline for these steps for each section will be the following:

```
first_section_alerts =
    opts
    |> Alert.fetch()
    |> Enum.filter(&relevant?/1)
    |> choose_alert()

second_section_alerts = []
if length(sections) == 2 do
    second_section_alerts =
        opts
        |> Alert.fetch()
        |> Enum.filter(&relevant?/1)
        |> choose_alert()
end

alerts = first_section_alerts ++ second_section_alerts
```

If screen is configured with only one section, `alerts` will contain up to one item. If there are two sections configured, `alerts` will contain up to two items.

With this list, we create three `WidgetInstance` objects for each rotation:

```
[
  %DupAlert{screen: config, rotation_index: 0, alerts: alerts},
  %DupAlert{screen: config, rotation_index: 1, alerts: alerts},
  %DupAlert{screen: config, rotation_index: 2, alerts: alerts}
]
```

### WidgetInstance

In `WidgetInstance.DupAlert`, the following type will be used for the struct:

```
@type t :: %__MODULE__{
          screen: Screen.t(),
          alerts: [Alert.t()] | [Alert.t(), Alert.t()],
          rotation_index: 0 | 1 | 2
        }
```

\*Although the struct can take a list of two alerts, only the first alert in the list will ever be displayed on the screen.

Because irrelevant alerts are filtered out in the `CandidateGenerator`, we are able to always return `true` from `valid_candidate?/1`.

A function `get_region_and_headsign(alert, parent_stop_id)` will be created based on the logic from [this function](/lib/screens/dup_screen_data/data.ex#L11). This function will be used by `serialize/1` to determine an alert's region and headsign. If `region == :inside`, `headsign` is `nil`. If `region == :boundary`, `headsign` is populated using [this map](/config/config.exs#L86).

`slot_names/1` will need to use different logic for each rotation. See spec for details.

Two serialize functions will be created: `serialize_partial_alert/1` and `serialize_takeover_alert/1`.

`serialize_partial_alert/1` returns the following map:

```
%{
    alert_text: %FreeTextLine{icon: :warning, text: ...},
    color: :red | :orange | :green | :blue
}
```

`alert_text.text` is either `No ${headsign} trains` or `No ${line} service` depending on the value of `headsign` in the return of `get_region_and_headsign/2`.

`serialize_takeover_alert/1` returns the following map:

```
%{
    alert_text: %FreeTextLine{icon: :warning, text: ...},
    color: :red | :orange | :green | :blue,
    remedy: %FreeTextLine{icon: :shuttle | nil, text: ...}
}
```

The value of `alert_text` is the same as for `serialize_partial_alert/1`. `remedy.icon` is `:shuttle` if `alert.effect == :shuttle` and `nil` otherwise. `remedy.text` uses the following mapping:

```
@alert_remedy_text_mapping %{
    delay: "Expect delays",
    shuttle: "Use shuttle bus",
    suspension: "Seek alternate route",
    station_closure: "Seek alternate route"
}
```

[^1]: An applicable alert is an alert with an effect of `delay` with `severity` >= 5, `shuttle`, `suspension`, or `station_closure` that affects a `stop_id` from the `primary_departures` section of the DUP config.
[^2]: A `partial` alert takes up only a small amount of the screen to allow for other departures to remain visible.
[^3]: A `takeover` alert displays over the whole screen including the departures.
[^4]: Priority for DUP alerts is pick a shuttle alert if present. Otherwise, pick the first in the list.
