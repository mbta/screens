# Audio-only widgets

## Motivation
In the non-interactive context of our screens, audio content is qualitatively different from visual content. In particular, when consuming speech, users can't "seek" to the piece of information they're interested in—they need to keep listening until they hear it.

One way to mitigate this somewhat is to provide summaries in advance of what's about to be described in more detail.

For this reason, our application needs the ability to include content in a screen's audio-equivalent readout that doesn't map directly to any single widget. To produce "summary" content for the readout, we need to have insight into all of the widgets appearing on the visual app.

## Example
A certain screen type can show alert widgets (1 widget per relevant service alert).

For its audio readout, we want to give a short summary of the total number of alerts and the routes/lines that they affect, before reading out each alert's details. This gives riders a chance to know ahead of time whether any of the alerts might help inform their trip plans.

## Proposed solution
We will make this change at the framework level, adding support for a per-screen-type set of audio-only widgets to be added to the readout from a new candidate generator function.

Audio-only `WidgetInstance` modules will look and behave the same as other `WidgetInstance` modules, except they will have insight into relevant normal widget instances that need to be summarized. More on this [below](#widgetinstance).

### CandidateGenerator
Add a new callback, `audio_only_instances/2`, to the `CandidateGenerator` behaviour module. This new function will take the finalized list of visual widgets and the screen config, and return a list of zero or more audio-only widgets to be included in the readout.

Each module that adopts the `CandidateGenerator` behaviour must define `audio_only_instances/2`. In most cases, it will return an empty list: `def audio_only_instances(_widgets, _config), do: []`.

If we need to make additional API queries in `audio_only_instances/2` to provide needed data for one or more audio-only widgets, that's fine. Prefer doing that over digging around in existing widgets' data.

### WidgetInstance
Audio-only `WidgetInstance` module files will live in the namespace `Screens.V2.WidgetInstance.AudioOnly`. E.g. `Screens.V2.WidgetInstance.AudioOnly.AlertsSummary`.

Audio-only `WidgetInstance` defs will behave about the same as other modules implementing the `WidgetInstance` protocol, but in most cases their struct will have a `widgets_snapshot` field.

This field receives the finalized list of visual widgets that made it onto the screen and have defined audio equivalence, filtered to the ones that the audio-only widget needs to know about to produce its summary.
E.g., an alerts summary audio-only widget will receive the list of alert widgets that made it onto the screen.

They can do whatever they need to with the list, but ideally would not dig too deeply into any of the widgets within, since the intended use case is producing high-level summary content.

#### Differences from normal widgets
- These widgets get to have insight into other normal widgets. When instantiated, they are passed a list of other normal `WidgetInstance` structs that made it onto the screen and have defined audio equivalence. While this breaks the rule of keeping widgets' data isolated, it's necessary in order to build "summary" content in the readout. This also happens in a well-defined step, with normal widgets still isolated from other normal widgets and audio-only widgets isolated from other audio-only widgets.
- While these audio-only widgets will still implement the `WidgetInstance` protocol on the backend, their visual-specific callbacks like `priority/1` and `serialize/1` will never be called. Only the audio-specific callbacks will be called. We prefer to implement them this way for consistency with the rest of the framework. We may revisit this decision in a future refactoring task.

### ScreenAudioData
In `Screens.V2.ScreenAudioData`, we'll add a call to `candidate_generator.audio_only_instances/2` into this pipeline:
```diff
  config
  |> fetch_data_fn.()
  |> elem(1)
  |> Map.values()
  |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)
+ |> then(fn widgets_with_audio_implementations ->
+   Enum.concat(
+     widgets_with_audio_implementations,
+     candidate_generator.audio_only_instances(widgets_with_audio_implementations, config)
+   )
+ end)
  |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)
  |> Enum.map(&{WidgetInstance.audio_view(&1), WidgetInstance.audio_serialize(&1)})
```
In English:
- start with a screen's configuration,
- run the visual widget generation and placement logic with it,
- grab the visual widgets that made it onto the screen,
- filter down to the ones that have audio representations,
- **append any audio-only widgets to the list as defined by the screen type's candidate generator,**
- sort them by their "audio sort key",
- and serialize all audio widgets' data for SSML rendering.

(All code is added inline in the above example, but it might help to break it out into its own function for readability.)

All other framework logic will remain unchanged.
