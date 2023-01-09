# Screens app architecture

This doc gives a high-level overview of how Screens works.

Links to more detailed documentation can be found in [Detailed docs](#detailed-docs).

## Bird's eye view

### What does it do?

`screens` serves location-aware, real-time system information to all of the MBTA's **browser-based, non-interactive** screens posted at bus stops and rapid transit stations.

These screens come in a variety of forms and capabilities. Some support audio equivalence, for which the server produces on-demand readouts using AWS Polly.

### Architecture overview

This application is composed of one server and several different client app bundles. When a screen app is requested at `/v2/screen/{id}`, the server looks up the **screen type** associated with `id` in our configuration and serves the corresponding **client app**.

Each client app defines the UI behavior particular to a given screen type (e.g. bus E-Ink, Green Line E-Ink, pre-fare duo), but all client apps share some common traits:
- They are React apps designed to run in a standard web browser.
- With one exception, they poll the server regularly for new data to display.
- They are not interactive—none of our screens support user input.
- Their UI is divided into isolated parts called **widgets** that behave like mini-apps. More on this below.

Most of the backend code is concerned with telling a given screen (a.k.a. client app) what to display (or read out on its speakers) when the screen requests new data.

Screens need only identify themselves by their ID in requests—the server then looks up all of the necessary configuration to answer data requests for that screen using the ID.

Each screen's displayed content is composed of isolated parts called **widgets**. The concept of isolated widgets is used to organize our code all the way from the server through to the client, in both visual content and audio-equivalent readouts.

## Codemap

Server:
| Module or directory | Description |
| - | - |
| [`ScreenData`](/lib/screens/v2/screen_data.ex) | Common logic to answer all screen data requests. We try to keep this code agnostic of widget implementation details and free of business logic. Code changes infrequently. If a new feature is needed on _all_ screen types, the change might happen here. |
| [`config` directory](/lib/screens/config/) | Contains modules that define the config schema for each screen type. Most modules `use` a macro from [`config/struct.ex`](/lib/screens/config/struct.ex) to simplify defining their data structures. |
| [Candidate generators](/lib/screens/v2/candidate_generator/) | These modules define "step 1" for producing the data response for each screen type. Each one adopts the [`CandidateGenerator`](/lib/screens/v2/candidate_generator.ex) behaviour, and contains code that defines the screen's visual template as well as functions to fetch data and transform it into widgets to populate that template. |
| [`Template`](/lib/screens/v2/template.ex) | Contains types and functions related to screen templates.  |
| [`WidgetInstance`](/lib/screens/v2/widget_instance.ex) | Defines the common protocol that all widgets must implement. The framework code in `ScreenData` calls these protocol functions on widgets to fit them into a screen template and produce the JSON response. |
| [`widget_instance` directory](/lib/screens/v2/widget_instance/) | Contains definitions of all widgets. Business logic goes here. |
| [`ScreenController`](/lib/screens_web/controllers/v2/screen_controller.ex) | Responds to page load requests for screen clients. |
| [`ScreenApiController`](/lib/screens_web/controllers/v2/screen_api_controller.ex) | Responds to data requests initiated by screen clients. |
| [`ScreenAudioController`](/lib/screens_web/controllers/v2/audio_controller.ex) | Responds to audio readout requests initiated by screen clients. |
| [Audio views](/lib/screens_web/views/v2/audio/) | Contains logic to produce speech-synthesis markup language (SSML) from screen data, to be synthesized by AWS Polly. |

Client:
| Module or directory | Description |
| - | - |
| `// todo!` | - |


# Detailed docs

[Widget framework](/docs/architecture/widget_framework.md)
