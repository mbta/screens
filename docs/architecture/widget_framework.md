# Widget framework

The widget framework comprises common code that provides a "backbone structure" to our business logic.

Each screen's content is composed entirely of widgets, and when a screen requests new data, no matter which type it is, the same backend logic is used to look up the screen's configuration, fetch the appropriate real-time data, transform that data into "candidate" widgets, and then assemble some of those candidates together to be sent back to the client and rendered.

**See [Glossary](#glossary) below for term definitions.**

## What's a widget?

A widget is a self-contained piece of content. It's essentially a special type of Model (as in MVC) that can be dropped into template slots alongside any number of other widgets to form a full page of content.

Some examples of widgets include the departures list, subway status, alert cards, and image PSAs. However, even basic screen content like the header and footer are widgets as well.

On the backend, each widget implements the [`WidgetInstance` protocol](/lib/screens/v2/widget_instance.ex). The framework calls these protocol functions to find out each widget's priority and where it would like to appear on the screen. The framework then determines how best to position all available widgets within these constraints.

**Widgets do not directly communicate with one another, or even know about the existence of other widgets** <sup>(With one [well-defined exception](#feature-audio-only-widgets))</sup>. Widgets only communicate with the framework via the aforementioned protocol functions. Once created, a widget has all of the data it needs to render itself.

## Why widgets?

We have many screens, and many different _types_ of screens. Each one needs to display the most rider-relevant info for its specific location.

The widget framework allows us to automate the process of deciding what content is most relevant from moment to moment on a given screen.

The strict isolation of widgets prevents an explosion in complexity and interdependence. It also makes it possible to swap pieces of content out on a screen without worrying about potential side-effects. Business logic (of which there is much since the T has endless edge cases) is corralled inside `WidgetInstance`-implementing modules.

Once a widget is created, it has all of the data it needs. This means all functions on a widget are pure/free of side effects, and easy to test.

See the [`WidgetInstance` protocol](/lib/screens/v2/widget_instance.ex)'s inline documentation for details on each implementation function.

## Request data flow / how the framework logic works

Screens team members can see this as a [flowchart in Miro](https://miro.com/app/board/o9J_lDRaax4=/).
The module where most of this logic lives is [`Screens.V2.ScreenData`](/lib/screens/screen_data.ex), starting with `by_screen_id/2`.

1. Client requests `/v2/api/screen/{id}`. Subsequent steps take place on the server.
1. We get the config stored under `id` in the screen configuration file. The file lives in S3 and the Screens application caches its contents locally in a [GenServer](/lib/screens/config/state.ex).
1. We look up the "app ID" stored in the config. We get the appropriate candidate generator module for that app ID.
1. We get the template for this screen type by calling `candidate_generator.screen_template()`.
1. We get a list of candidate widgets for the screen by calling `candidate_generator.candidate_instances(config)`.
1. Candidates are sorted by priority (descending), and then placed into template slots one at a time until the template is filled. We call this populated template a "layout".
1. Paged sections of the template are pruned to just the current page, based on the current clock time.
1. Widgets are serialized to JSON-friendly maps and dropped into a map that reflects the chosen layout.
1. The map is converted to JSON and sent back to the client.
1. Client receives JSON response and passes it into the React component tree to render updates.

## Data flow for an audio readout request

Audio equivalence support is built into the framework.

Its data flow is about the same as the visual UI, but instead of being serialized to JSON and sent to the browser to be rendered by React, it is instead rendered to an SSML string on the server and piped through AWS Polly to produce an MP3 containing synthesized speech.

1. Client requests `/v2/audio/{id}/readout.mp3`. Subsequent steps take place on the server.
1. Steps **2** through **8** of the above data flow run as usual.
1. The data map is rendered to SSML using each widget's audio view.
1. The SSML is sent to Polly for synthesis, and we receive MP3 data in the response.
1. The MP3 is sent back to the client for playback.

## Philosophy / Where logic should go

As much as possible, we try to divide the logic as follows.

All network requests for real-time data happen in the candidate generator. After that, we should have a set of WidgetInstance structs that have all the info they need. That is, **besides the candidate generator, all WidgetInstance and ScreenData functions should be pure.**

Simple filtering can happen in the candidate generator. For example, we can avoid producing candidate widgets for alert data that has an effect we don't care about, like `SERVICE_CHANGE`.

Logic for more complex conditions that make a widget ineligible for placement should live inside the WidgetInstance module, in `valid_candidate?/1`.

The majority of the "heavy" business logic should live inside WidgetInstance modules.

The core framework logic—the algorithm that fits widgets into templates—should remain agnostic of any specifics of a given screen type or widget. It should only use protocol functions to manipulate widgets.

## Anatomy of a template

Each screen type has a template that defines the "slots" that widgets can fit into, as well as layout variations for special cases like high-priority alerts that take over all space below the screen header.

A template is a recursive data structure.

The base case is a "slot ID"—a simple named space that a widget can drop into.

The recursive case is a tuple representing a region containing one or more layout variations: `{region_id, %{layout_id => list(template)}}`. Let's break that down:

- `region_id`: the region's name. For example: `:body`, `:flex_zone`, `:screen`.
- `layout_id`: a name for one possible set of slots that can fill this region. For example: `:body_normal`, `:body_takeover`; `:one_large`, `:two_medium`.
- `list(template)`: the set of slots, or even further nested regions, that fill this region under the given layout variation.

Layout variations provide a mechanism for high-priority widgets, like urgent alerts, to take over large portions of a screen. They also allow paged regions to hold widgets of different sizes per page.

## Feature: Paging

Some screen types have paged regions, where the widgets that appear in the region can rotate over the course of several data refreshes.

Most paging logic lives on the backend. The current page is selected based on the screen type's data refresh rate (e.g. 20 sec for pre-fare duo) and the current clock time.

During the serialization step, all pages except the current one are discarded. This means the React client is only aware of the content of the current page at any given moment.

### Why backend paging?

**Our current reasoning is as follows, but we occasionally revisit this approach and it might change in the future.**

Since it takes a minute or more to cycle through all pages when there are 3 or more, if the frontend received all pages to cycle through at once and didn't request new data until it was done, the last page would be somewhat "stale" and at risk of being out of date.

By keeping the backend in control of paging, content stays real-time, all the time.

### Persistent front-end widgets and frontend paging

A small number of widgets perform paging internally, entirely on the client. These include the elevator status widget and the pre-fare "full line map" widget. They use a [special function](/assets/src/components/v2/persistent_carousel.tsx#L99) to create a component that cycles through one page at a time, ignoring new data from the backend until it finishes consuming the pages it last received.

To the backend, they are just normal widgets—it sends data for them in every response, and the client chooses whether or not to discard it.

We use persistent widgets when the number of pages is variable, and when all pages are part of the same widget—as opposed to cycling through a heterogeneous list of e.g. alerts and PSAs.

This approach does have the downside of "stale" data mentioned in [**Why backend paging?**](#why-backend-paging).

## Feature: Audio-only widgets

Because the semantics of speech don't allow for the same "scannability" as a visual UI, we occasionally need to provide a summary of content before it's read out, so that the rider can decide whether it's relevant to them.

To achieve this, we support "audio-only widgets". These are special "privileged" widgets that come into play after all other widgets have been placed, and each receive a full snapshot of all of the visual widgets being displayed.

This breaks the isolation that we enforce on all other widgets, but audio-only widgets are expected to only provide high-level summary content. For example, describing which subway lines (if any) have active service alerts before elaborating on the content of each alert.

## Glossary

| Term | Definition | Example |
| - | - | - |
| **Widget** | A self-contained and isolated "mini-app" that displays some info on a screen. | Departures list, alert, subway status, header, evergreen content |
| **Candidate generator** | A backend module responsible for fetching real-time data and converting it to **candidate** widgets. Each screen type has one candidate generator module. | [Pre-fare candidate generator](/lib/screens/v2/candidate_generator/pre_fare.ex) |
| **Candidate** | A **widget** that has not yet been definitively placed in the **layout**. | A piece of evergreen content that may or may not get "bumped" off the screen by higher-priority widgets like alerts. |
| **Template** | A tree-like data structure that describes the **regions** and **slots** of a screen type, and resolves to one of several possible **layouts** when combined with **candidate** widgets. Each screen type has one template, defined in its **candidate generator** module. | [Bus shelter template](/lib/screens/v2/candidate_generator/bus_shelter.ex#L18) |
| **Region** | An area of a screen that contains one or more **layout variations**. | [`:body` region on the pre-fare template](/lib/screens/v2/candidate_generator/pre_fare.ex#L24-L53) |
| **Layout variation** | One way to fill a **region** with **slots**, or even further nested **regions**. | [`:body_normal` and `:body_takeover` on the pre-fare template](/lib/screens/v2/candidate_generator/pre_fare.ex#L26-L52) are two layout variations. |
| **Layout** | A tree-like data structure produced by resolving all of a **template**'s **layout variations** to a defined set of **slots**. The layout is selected by placing **widgets** into the **template** one at a time in priority order, removing **layout variations** that each one cannot fit in. | Pre-fare template with selected layout variations: `:body_normal`, `:body_left_normal`, `:body_right_takeover`. |
| **Slot** | A uniquely labeled space with fixed pixel dimensions and position, which one **widget** can occupy. Slots are the "leaf nodes" of a **template**'s tree structure. | On pre-fare screens, `:header`, `main_content_left`, `:full_body_left`, `:large`, `:medium_left`, `:full_screen`, and so on. |
