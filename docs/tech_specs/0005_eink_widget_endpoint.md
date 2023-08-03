- Feature Name: `eink_widget_endpoint`
- Start Date: 2023-07-28
- RFC PR: [mbta/technology-docs#0000](https://github.com/mbta/technology-docs/pull/0000)
- Asana task: [asana link](https://app.asana.com/0/1185117109217413/1205119093140586)
- Status: Proposed

# Background
[background]: #background

The new Mercury hardware requires adjustments to the e-ink frontend, to meet battery-saving requirements. Mercury will provide a sort of "skin" to the data provided from the app backend. The widgets of the screen that change every 30 seconds will be built in-house by the Mercury team: departures & line map widgets. The widgets that have a longer lifespan will be provided by us.

Originally, this involved making static images of widgets available to Mercury, but they said they could use a url and take screenshots, a process they've used previously. The widgets we need to provide through a new endpoint:
- Header (except for clock? We'll ask Mercury how they'd like to build that)
- Evergreen
- Footer
- Subway status
- Alerts

# Summary
[summary]: #summary

It would be great for these widget endpoints to avoid re-running the backend logic, if it can be avoided. The full screen data was already generated and passed to the Mercury skin, so to look up a particular widget, the skin can take the individual widget json and send it in the body of a POST request to a screen-specific endpoint.

# Explanation
[explanation]: #explanation

### Backend routing

A new route can be added to the Phoenix router, one that gets us to the correct e-ink app (Green Line or Bus) and then lets us POST with a json body.

`post "/:id/widget", ScreenController, :widget`

This requires a new handler in the ScreenController:

```
  def widget(conn, %{"id" => app_id} = params)
      when app_id in @app_id_strings do
    app_id = String.to_existing_atom(app_id)
    
    conn
    |> assign(:app_id, app_id)
    |> assign(:widget_data, (if params["widget"], do: Poison.encode!(params["widget"]), else: nil))
    |> render("index_widget.html")
  end
```

(I used Postman to confirm that this set-up properly adds the stringified json to the app container in `index_widget.html`. But I don't know of a way to test a POST right in the browser, so to make this easier to test, I also added a GET route:  `get "/:id/widget", ScreenController, :widget`)

Since the handler needs to catch both GETs and POSTs for the moment, there needs to be some flexibility (i.e. params may / may not include a post body, may / may not have a field called `widget`). The `index_widget.html` is simple, only passing `app_id`, `environment_name`, and `widget_data` to the frontend.

### Expected data format

The data format expected for the POST body is the individual widget, where the static state is isolated*. (More on that in a minute.) The widget data must also be wrapped in a `widget` field, so the `ScreenController` can recognize the correct param. An example of footer widget data could look like:

```
"footer": {
    "mode_cost": "$2.40",
    "mode_icon": "subway-negative-black.svg",
    "mode_text": "Subway",
    "text": "For real-time predictions and fare purchase locations:",
    "type": "fare_info_footer",
    "url": "mbta.com/stops/place-bcnwa"
}
```

And then the POST request body should be structured like:
```
{
    "widget": {
        "footer": {
            "mode_cost": "$2.40",
            "mode_icon": "subway-negative-black.svg",
            "mode_text": "Subway",
            "text": "For real-time predictions and fare purchase locations:",
            "type": "fare_info_footer",
            "url": "mbta.com/stops/place-bcnwa"
        }
    }
}
```

*Where static state is isolated - what's that mean? The paging widget is interesting because it is kinda a container widget for static widgets. Mercury will need to build the paging part because it changes every 30 seconds, and the parts we will provide are the static underlying widgets. So if in the whole-screen JSON, the flex zone widget is represented by:
```
"flex_zone": {
    "medium": {
        "asset_url": "https://mbta-screens.s3.amazonaws.com/screens-prod/images/e-ink/psa/MBTA SEE SAY_Eink-Messaging.png",
        "type": "evergreen_content"
    },
    "num_pages": 2,
    "page_index": 1,
    "type": "one_medium"
}
```

Then the bit that should be passed in the POST request is a step deeper at the `medium` level. The request body should be:
```
{
    "widget": {
        "medium": {
            "asset_url": "https://mbta-screens.s3.amazonaws.com/screens-prod/images/e-ink/psa/MBTA SEE SAY_Eink-Messaging.png",
            "type": "evergreen_content"
        }
    }
}
```

### Frontend rendering

In both `gl_eink.tsx` and `bus_eink.tsx`, there will be a new route to match on the exact path for that screen type: e.g. `/v2/screen/gl_eink_v2/widget` or `/v2/screen/bus_eink_v2/widget`. That route will render a new type of page, `<WidgetPage />`, which takes no props. Instead, it reads the `data-widget-data` from the html app container. That value will be a string, so it will need to be parsed into json.

```
const WidgetPage = () => {
  const widget = getDatasetValue("widgetData")
  let widgetJson = widget ? JSON.parse(widget) : null
  if (widgetJson) widgetJson = Object.values(widgetJson)[0]

  return widgetJson ? <Widget data={widgetJson} /> : null
};
```

And then suddenly, the widget page is rendered! Mercury will be taking screenshots of these pages and sending the image to the screen, only to update with a new screenshot if the data for that widget changes.

Example 1: Footer. POST to http://localhost:4000/v2/screen/gl_eink_v2/widget with body
```
{
    "widget": {
        "footer": {
            "mode_cost": "$2.40",
            "mode_icon": "subway-negative-black.svg",
            "mode_text": "Subway",
            "text": "For real-time predictions and fare purchase locations:",
            "type": "fare_info_footer",
            "url": "mbta.com/stops/place-bcnwa"
        }
    }
}
```

displays:
![example eink footer][example eink footer]

Example 2: Partial alert. POST to http://localhost:4000/v2/screen/gl_eink_v2/widget with body
```
{
    "widget": {
        "medium": {
            "body": "Shuttle buses replacing Green Line E branch service",
            "header": "Shuttle Buses",
            "icon": "bus",
            "route_pills": [
                {
                    "color": "green",
                    "text": "Green Line E",
                    "type": "text"
                }
            ],
            "type": "alert",
            "url": "mbta.com/alerts"
        }
    }
}
```

displays:
![example partial alert][example eink partial alert]

Example 3: Takeover alert. POST to http://localhost:4000/v2/screen/gl_eink_v2/widget with body
```
{
    "widget": {
        "body": {
            "full_body_bottom_screen": {
                "type": "bottom_screen_filler"
            },
            "full_body_top_screen": {
                "body": "Heath Street closed",
                "header": "Station Closed",
                "icon": "x",
                "route_pills": [
                    {
                        "color": "green",
                        "text": "Green Line E",
                        "type": "text"
                    }
                ],
                "type": "full_body_alert",
                "url": "mbta.com/alerts"
            },
            "type": "body_takeover"
        }
    }
}
```

displays:
![example takeover alert][example eink takeover alert]

# Unresolved Questions
- Are the MappingContext and ResponseMapperContext needed as wrappers for `<WidgetPage />`?
- What about slots?
  - Since Mercury is building their own frontend skin, I believe the layout and sizing needs to be managed on their end. Is that true?

# Drawbacks
[drawbacks]: #drawbacks

???

# Rationale and alternatives
[rationale-and-alternatives]: #rationale-and-alternatives

Are there any alternatives that would avoid needing to re-run the backend code? (And are there any drawbacks of the current approach that make this re-run worth it?)


[example eink footer]: /docs/assets/sample_app_screenshots/widgets/example_eink_footer.png
[example eink partial alert]: /docs/assets/sample_app_screenshots/widgets/example_eink_partial_alert.png
[example eink takeover alert]: /docs/assets/sample_app_screenshots/widgets/example_eink_takeover_alert.png
