# Screens by alert real-time data source

## The need
[Screenplay][screenplay] designs include several features that **depend on the ability to know, in real time,
which screens are currently displaying info about which service alerts**.

![alert places design][screenplay places with alert]
<sup>This screenshot from the designs shows the "Alert Places" view, which lists all of the screens currently
displaying information about a user-selected service alert.</sup>

Currently, `screens` is not able to provide this information.

## The technical problem
This data is best provided as a mapping from alert ID to a list of screen IDs.

This new source of real-time data is not straightforward to implement, because
each screen's content is populated using a priority-based algorithm in which
any one piece of content can "evict" one or more other pieces if its priority
is higher.

Simply put: to accurately answer "which alerts are on this screen?", the server must do the same amount of work as it does to compute all content on the screen.

To answer this query for _all_ screens, which is required to produce the full listing required by Screenplay, the server would need to do
this work separately for every screen.

We have implemented a similar new piece of Screens data for Screenplay: a list of "flex zone" widgets shown on each screen.

![foo][screenplay simulation with flex widgets list]
<sup>A simulation for one screen, with a list of its currently-displayed "flex zone" widgets to the side.</sup>

However, this is only fetched for one screen at a time, on demand. Doing it for all screens at once would likely cause performance
problems, both for the Screens server and for the Screenplay client, for exactly the same reasons as this new data.

The new `alert -> screens` mapping _requires_ knowledge of this data for all screens, since it's used to determine the members of
a filtered list of screens and other alert-related features.

## Reasoning about the problem

This data source is not trivial to implement because it would be computationally expensive (both in terms of CPU usage and number of ensuing requests to the V3 API) to produce anew every time it's requested.

The problem might be tackled in two ways:

1. Make it less computationally expensive to determine what alerts are currently being shown on a given screen
2. Spread the computation out over time and cache the results piecemeal

We do not think (1) is feasible, because this piece of data has a large set of dependencies:
- the current state of the system,
- the current configuration of each screen,
- the internal logic of each widget that can appear on the screen,
- and the higher level logic of the "widget framework" which assembles widgets together to produce the full layout.

So the proposed solution in this doc attempts (2).

## Proposed solution

**Summary: Use some sort of caching layer, with cached data updated piecemeal as the server responds to each screen data request.**

While it would be too expensive to compute the full real-time `alert -> screens` mapping from scratch every time it's needed,
the Screens app already does the work necessary to produce this mapping over the course of every 30 seconds or so, in responding
to data requests for all of our active screens. It just doesn't save each key/value pair anywhere.

The proposal is to [memoize][wiki:memoization] this work by keeping the mapping in state _somewhere_, and keep it updated piece-by-piece
every time the Screens server responds to a new screen request.

![diagram of proposed solution][solution diagram]
<sup>Every time a Screens client requests data, the server
stores details about the results in a stateful process. When Screenplay
requests the screens-by-alert mapping, this process provides that data.</sup>

### TTL and self-refresh

Since the primary mechanism for keeping this data source up to date is the Screens server responding to requests from Screens clients, we run into problems when a client goes down for some reason.

We propose implementing a per-screen [TTL][wiki:TTL] and automatic self-refresh to avoid having parts of the data source go out of date.

More details on this in [_Shape of the data_](#shape-of-the-data) below.

### Where to store the data

We initially considered an Agent or GenServer, but this might run into complications since Screens prod always has at least 2 instances running behind a load balancer.

A safer option might be a data store that lives separate from the Screens server and is shared by the 2+ server instances:
- a redis cache?
- a database of some sort?

### Shape of the data

The proposed structure of the data is a simple map: `%{alert_id => list(screen_id)}`.\
This could change, but the shape we ultimately choose hopefully won't have too much of an impact on the overall implementation.

We will also most likely need to store some metadata in order to implement per-screen TTL.
```ex
%{
  screens_by_alert: %{alert_id => list(screen_id)},
  data_last_updated: %{screen_id => DateTime.t()}
}
```

One potential alternative to this timestamp-based approach is to schedule the
expiration and automatic self-refresh of each piece of data at the same time
as it's added, and cancel any scheduled expirations whenever new data comes in.

Data structure:
```ex
%{
  screens_by_alert: %{alert_id => list(screen_id)},
  timers: %{screen_id => reference()}
}
```

Sample code for the stateful process:
```ex
def handle_cast({:put_data, screen_id, data}, state) do
  state = cancel_and_delete_ttl_timer(state, screen_id)

  timer = Process.send_after(self(), {:expire_and_refresh_data, screen_id}, @ttl_ms)

  state =
    state
    |> put_ttl_timer(screen_id, timer)
    |> put_data(screen_id, data)

  {:noreply, state}
end


def handle_info({:expire_and_refresh_data, screen_id}, state) do
  timer = Process.send_after(self(), {:expire_and_refresh_data, screen_id}, @ttl_ms)

  # We most likely wouldn't put the whole response data into state, but this is a simplified example.
  #
  # We would likely also want to do this (expensive) work in a separate process to prevent the
  # state process from being blocked while waiting for the result.
  data = ScreenData.by_screen_id(screen_id)

  state =
    state
    |> delete_data(screen_id)
    |> put_ttl_timer(screen_id, timer)
    |> put_data(screen_id, data)

  {:noreply, state}
end
```

## Questions
1. Is the concern about multiple prod server instances causing duplicated/incomplete data valid?\
   Is there a way to have the instances communicate to maintain a consistent and complete picture of the state, rather than having each instance independently keep its own Agent/GenServer up to date?
2. (If we choose this approach) How to set up a Redis cache, DB, or other separate data store for use by an instance deployed to ECS?


[screenplay]: https://github.com/mbta/screenplay
[screenplay design]: https://github.com/mbta/screenplay
[screenplay places with alert]: ../assets/screenplay_places_with_alert.png
[screenplay simulation with flex widgets list]: ../assets/screenplay_simulation_with_flex_widgets_list.png
[wiki:memoization]: https://en.wikipedia.org/wiki/Memoization
[solution diagram]: ../assets/screenplay_screens_by_alert_implementation_diagram.png
[wiki:TTL]: https://en.wikipedia.org/wiki/Time_to_live
