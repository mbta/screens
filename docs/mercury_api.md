# Mercury E-ink APIs

[Mercury] is our vendor for E-ink screens. Unlike our other screens, Mercury
screens do not use an on-device web browser to request and display our "screen
app" web pages. Instead, a central system directly requests the JSON widget
data from our API and ultimately transforms this into screenshots of individual
widgets, with this image data then being sent to the E-ink devices.

This has a couple of important consequences:

1. Our widget API is *not* purely internal to the Screens app. Mercury is a
   client of this API and changes to how layouts or widgets are serialized can
   affect them.

2. Our API includes fields that appear "unused" from the perspective of our own
   client, but are required by the Mercury client.

This document collects in one place our "API contract" with Mercury,
specifically with regard to the second point. It should be updated if this
contract changes.

[Mercury]: https://www.notion.so/mbta-downtown-crossing/Mercury-e-ink-8ee536ab5ffe46e482d5359f443d74ed#8ee536ab5ffe46e482d5359f443d74ed


## Widget endpoint

The `/widget/:app_id` endpoint is used only by the Mercury client. This accepts
a `widget` parameter containing the JSON data of a single widget (as returned
from the screen data API), and renders a web page containing only that widget.
[[#1909]]

See [`tech_specs/0005_eink_widget_endpoint.md`][spec] for additional background.

[spec]: tech_specs/0005_eink_widget_endpoint.md


## Top-level fields

The screen data API returns a JSON object. Normally the only interesting field
here is `data`, the screen's root layout (which then contains other layouts and
widgets, [and so on](architecture/widget_framework.md)). For Mercury screens,
we include the following additional fields:

* `audio_data` *(string)* — The SSML of the screen's audio readout. Mercury
  uses this to produce their own audio readouts; the E-ink screens do not use
  our MP3 audio API. [[#1913]]

* `flex_zone` *(array)* — All of the widgets selected for display in paged
  slots (normally paging is resolved on the server and only the current page
  is sent to the client). Uses the same logic as "Screenplay simulations", but
  not the same response structure. [[#2317]]

* `last_deploy_timestamp` *(string)* — The datetime the app was last deployed,
  in ISO8601 format. [[#1909]]


## `Departures` widget

For E-ink screens, each of `sections[].rows[].times_with_crowding[]` has a
`time_in_epoch` *(integer)* field, which is the predicted departure time as a
Unix timestamp. This allows the conversion to a number of minutes or "Now" to
be done "just in time", independent of data fetching. [[#1911]]


## `LineMap` widget

Each of `vehicles[]` has a `time_in_epoch` *(integer)* field, which has the
same meaning and purpose as above. [[#1970]]


## `NormalHeader` widget

For Mercury screens, the `time` field is omitted. This hides the clock that
normally appears in screen headers, allowing the Mercury system to dynamically
add its own clock independent of data fetching and widget rendering. [[#1943]]


[#1909]: https://github.com/mbta/screens/pull/1909
[#1911]: https://github.com/mbta/screens/pull/1911
[#1913]: https://github.com/mbta/screens/pull/1913
[#1943]: https://github.com/mbta/screens/pull/1943
[#1970]: https://github.com/mbta/screens/pull/1970
[#2317]: https://github.com/mbta/screens/pull/2317
