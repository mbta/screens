# Global audio widgets

## Name options
- global audio widget
- audio-only widget
- audio summary widget
- audio meta-widget

In the text below, I assume we stick with "global audio widget".

## Motivation
In the non-interactive context of our screens, audio content is qualitatively different from visual content. In particular, when consuming speech, users can't "seek" to the piece of information they're interested in—they need to keep listening until they hear it.

One way to mitigate this somewhat is to provide summaries in advance of what's about to be described in more detail.

For this reason, our application needs the ability to include content in a screen's audio-equivalent readout that doesn't map directly to any single widget. To produce "global" or "summary" content for the readout, we need to have insight into all of the widgets appearing on the visual app.

## Example
A certain screen type can show alert widgets (1 widget per relevant service alert).

For its audio readout, we want to give a short summary of the total number of alerts and the routes/lines that they affect, before reading out each alert's details. This gives riders a chance to know ahead of time whether any of the alerts might help inform their trip plans.

## Proposed solution
We will make this change at the framework level, adding support for a per-screen-type set of global audio widgets to be added to the readout from a new candidate generator function.

Global audio `WidgetInstance` modules will look and behave the same as other `WidgetInstance` modules, except their struct defs will have a `widgets_snapshot` field that receives the entire finalized list of visual widgets that made it onto
the screen and have defined audio equivalence, sorted by their audio sort keys.

### CandidateGenerator
Add a new callback, `insert_global_audio_instances/2`, to the `CandidateGenerator` behaviour module. This new function will take the finalized list of visual widgets and the screen config,
and return a new list with global audio widgets inserted at any location(s) within it. It can also return the input list unchanged.

Each module that adopts the `CandidateGenerator` behaviour must define `insert_global_audio_instances/2`. In most cases, it will return the input list unchanged: `def insert_global_audio_instances(widgets, _config), do: widgets`.

### WidgetInstance
Global audio `WidgetInstance` module files will live in the namespace `Screens.V2.WidgetInstance.GlobalAudio`. E.g. `Screens.V2.WidgetInstance.GlobalAudio.AlertsSummary`.

#### Differences from normal widgets
- These widgets get to have insight into other normal widgets. When instantiated, they are passed a snapshot of the entire list of normal `WidgetInstance` structs that made it onto the screen and have defined audio equivalence. While this breaks the rule of keeping widgets' data isolated, it's necessary in order to build "summary" content in the readout.
- While these audio-only widgets will still implement the `WidgetInstance` protocol on the backend, their visual-specific callbacks like `priority/1` and `serialize/1` will never be called. Only the audio-specific callbacks will be called. We prefer to implement them this way for consistency with the rest of the framework.

### ScreenAudioData
In `Screens.V2.ScreenAudioData`, we'll add a call to `candidate_generator.insert_global_audio_instances/2` into this pipeline:
```diff
  config
  |> fetch_data_fn.()
  |> elem(1)
  |> Map.values()
  |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)
  |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)
+ |> candidate_generator.insert_global_audio_instances(config)
+ |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)  # may need to sort once more
  |> Enum.map(&{WidgetInstance.audio_view(&1), WidgetInstance.audio_serialize(&1)})
```
In English:
- start with a screen's configuration,
- run the visual widget generation and placement logic with it,
- grab the visual widgets that made it onto the screen,
- filter down to the ones that have audio representations,
- sort them by their "audio sort key",
- **add any global audio widgets to the list as defined by the screen type's candidate generator,**
- and serialize all audio widgets' data for SSML rendering.

All other framework logic will remain unchanged.
