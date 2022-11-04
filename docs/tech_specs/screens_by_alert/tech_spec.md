# Screens by alert real-time data source - tech spec

## Need

Screenplay (and maybe other services, in the future) needs real-time insight into which screens are
displaying info about a given service alert.

As an added requirement, this data should represent the "idealized state" of the screens ecosystem—that is, if a particular screen client is down for some reason (hardware issues, network issues, a client code bug that we haven't addressed yet), the data should still represent what that screen _would be_ showing if the client were running properly.

## High-level architecture

To store and provide this new data, we will add a new caching layer to the Screens application.

To keep the cache in one shared location, we will use memcached rather than an ETS table or GenServer/other stateful process running on each server instance. This follows the precedent of the V3 API, which uses memcached to keep track of per-user request counts and apply throttling appropriately no matter how many instances it's scaled to.

### Data structure

Cached values will be as follows, defined as Elixir typespecs:
```ex
@type alert_id :: String.t()
@type screen_id :: String.t()
@type timestamp :: integer()  # we'll use System.system_time(:second) to produce these
@type timestamped_screen_id :: {screen_id, timestamp}

@type cache :: %{
  "screens_by_alert." <> alert_id => list(timestamped_screen_id),
  # metadata to make the "self-refresh" mechanism possible
  "screens_last_updated." <> screen_id => timestamp
}
```

<details>
  <summary>Detailed reasoning (long, sorry!)</summary>

  - - -

  ## What we're _not_ doing, and why

  Ideally, the data structure being stored is a "bipartite graph", or a "bidirectional map". We need to be able to look up values in two directions:
  - **screen ID -> alert IDs**: to facilitate updates to the cached data—we look up the previous value to determine which alerts, if any, have been removed.
  - **alert ID -> screen IDs**: to answer the original "what screens are showing this alert" question.

  This would allow us to always keep a fully accurate picture of what screens are showing what alerts.

  ![data structure diagram][data structure diagram]

  **However**, to implement such a data structure in code, we'd need to have some duplicate data. We'd need a cache key for every way you can do a lookup, so there would be keys for every screen _and_ every alert that's displayed on at least one screen.

  On top of that, every data update would require a potentially large number of updates to separate cache keys. Unfortunately, memcached is not designed for transactional/locking multi-key updates, so we would likely encounter race conditions and data inconsistency with the frequency of data updates and two separate server instances writing to the shared cache.

  ## What we're doing, and why

  **The cache will rely on data updates to be aware of the _presence_ of a given alert on a given screen, and will rely on data expiring from the cache to be aware of the _new absence_ of a given alert from a given screen.**

  This approach allows us to cache the data as a regular old map, and perform fewer cache operations in response to each screen data update.

  By not explicitly tracking which screens are no longer present, we can reduce the number of cache operations per data update.

  Cached screen IDs under an alert will each be paired with an update timestamp, and expired screen ID will be removed from the list whenever an alert key is updated.

  Alert keys will also have a TTL handled by memcached. memcached will remove any alert keys that don't receive an update within that TTL.

  In order to track when each screen update last happened and make the "self-refresh" mechanism possible, we will also store screen ID => timestamp values.

  - - -

</details>

### Timers and TTLs

In addition to the actual structure of the data being stored in the cache, we also need to carefully choose various timings and cache TTLs to properly keep that data up to date.

TTLs in our case are also somewhat tricky, because some of them will be carried out internally by memcached, and others will need to be carried out by us in Elixir code.

**Timers**
| timer | interval (sec) | Why? |
| - | - | - |
| "self-refresh" job-runner GenServer | 35 | Job should give the slowest screen clients (e-ink, 30 sec refresh rate) time to make their requests. |

**TTLs**
| value | Handled by | TTL (sec) | Why? |
| - | - | - | - |
| `screens_by_alert.*` cache items | memcached | 40 seconds | A key should expire shortly after a self-refresh runs without updating that key. |
| screen IDs listed under a `screens_by_alert.*` key | application logic | 40 seconds | A screen ID should expire from the list shortly after a self-refresh runs without reaffirming the ID's place in the list. |
| `screens_last_updated.*` cache items | memcached | 1 hour to 1 day | Value not very important as we will just stop looking up screen IDs that have been removed from the config/hidden from Screenplay. TTL is mainly for "cleanup" purposes |

TTLs handled by our application logic will be implemented by storing timestamp values in the cache, and comparing those timestamps with the current time when we read them again sometime later. I.e., whenever we update the list of screen IDs under an alert ID key, we'll also clear out any expired items. This cleanup can also happen when the list is read while responding to a `GET /api/screens_by_alert` request.

We will use `System.system_time(:second)` to produce unix timestamps. Elapsed time in seconds between two unix timestamps can be computed as follows:
```ex
time1 = System.system_time(:second)
time2 = System.system_time(:second)

time2 - time1
```

### Serialization format

To store and retrieve cached values, let's use `:erlang.term_to_binary/1` and `:erlang.binary_to_term/2` with the `[:safe]` flag argument.

`memcachex` provides a [Memcache.Coder.Erlang][hexdocs:memcachex erlang coder] module that does this for us. We can configure it to decode
using the `[:safe]` flag when we set up the connection:
```ex
Memcache.start_link([coder: {Memcache.Coder.Erlang, [:safe]}], <genserver_opts>)
# (Or pass the equivalent child spec to a supervisor)
```

<details>
  <summary>Reasoning</summary>

  - - -

  Since the following are true:
  - The cache is only accessible to our application; that is, it's a trusted source
  - The cache is only used to store and retrieve Elixir terms

  we can take advantage of Erlang's binary term storage format
  to store the cached data. This confers two advantages over JSON:

  1. Serialization/deserialization runs about twice as fast as `Jason.encode!/1` and `Jason.decode!/1`, per some quick tests I ran
  2. We aren't limited to JSON-serializable values. We can store and retrieve structs unchanged—e.g. `DateTime`s and `MapSet`s—as well as maps with atom keys, without any extra logic on the deserialization side. `:erlang.binary_to_term/2` will fully restore any term for us.

  - - -

</details>

## Detailed implementation plan

The plan is broken into steps corresponding to the numbered labels in this diagram.

![implementation diagram][implementation diagram]
  <sup>Diagram of the implementation plan. New components and logic are marked with green numbered labels.</sup>

### 1. Set up memcached

Add new terraform configuration to attach an ElastiCache service to the Screens application.

[Relevant slack thread][api elasticache slack thread]\
[How this is done for V3 API][api elasticache terraform config]

**Note: the `cache.m3.medium` node type used in the referenced config is deprecated; we should use a different node type when setting ours up. Check with Ian on this!

### 2. Write Screens logic to maintain data in memcached (for deployment environments) as well as a stateful Elixir process (for local dev)

The logic should be called at some point during the core widget framework logic, once we know which widgets have made it onto the screen.

The V3 API uses the `memcachex` Elixir library ([GitHub][memcachex github], [hexdocs][memcachex hexdocs]) to talk to memcached. We should probably do the same.

Since we will _not_ be using memcached in local development, we should define a Behaviour module to express the available functions for this feature, and have our memcached client module adopt that Behaviour. **A second module should be defined that implements the same functions but uses a GenServer/other stateful process or ETS table as the data store.** For an example of this programming pattern, [see the API's rate limiter modules][api rate limiter modules].

The behaviour should have the following callbacks (and modules that adopt it should implement them):

1. Put new data into the cache.\
   `@spec put_data(screen_id, list(alert_id)) :: :ok`\
   New cache data from one screen will be distributed across several cache keys, since our updates come in as lists of 0 or more alerts keyed on a screen ID, but the cache is keyed on alert ID), updating TTL metadata at the same time.
2. Read data for one `screens_by_alert.*` cache key.
3. Read data for one `screens_last_updated.*` cache key.

[Some V3 API code that interfaces with memcached][api memcached code]\
[List of available memcached commands][memcached commands doc]

### 3. Write new GenServer to handle "self-refresh" of expired data

The GenServer should, on a regular basis (once every 1 minute, probably):
1. Get a list of all currently registered screen IDs in config, with hidden-from-screenplay IDs filtered out. It can ask the `Screens.Config.State` GenServer for this data. `Screens.Config.State` should be updated to provide a new client function to provide the data. Our new GenServer should _not_ get the entire config state value from `Screens.Config.State` and do the filtering itself—this would cause performance issues.
2. Identify expired data by checking `screens_last_updated.*` cache values for each screen ID, and run the widget framework logic for those screens (thus updating the cached data), throwing away the returned value.

### 4. Add new endpoint to Screens server to expose screens-by-alert data to external clients

Suggested route path: `/api/screens_by_alert`.

The endpoint should accept a comma-separated list of 1 or more alert IDs, and respond with a JSON blob of the form
```ts
{
  "screens_by_alert": {
    [AlertID]: ScreenID[]
  }
}
type AlertID = string;
type ScreenID = string;
```

If no alert IDs are provided in the request, the response JSON should contain an empty `screens_by_alert` object.

### 5. Write Screenplay logic to fetch and use screens-by-alert data

TBD on how we will implement this in Screenplay. It could happen on the client or the server, and the data may be combined with other data from the V3 API or otherwise. The important thing is that the data is now available!


[implementation diagram]: /docs/assets/screenplay_screens_by_alert_final_implementation_diagram.png
[hexdocs:memcachex erlang coder]: https://hexdocs.pm/memcachex/Memcache.Coder.Erlang.html
[api elasticache slack thread]: https://mbta.slack.com/archives/CSZEKL4G4/p1663876864825769
[api elasticache terraform config]: https://github.com/mbta/devops/blob/0b698ae72ba68a24c31c836c591fdca99ea67113/terraform/prod/api.tf#L167-L179
[memcachex github]: https://github.com/ananthakumaran/memcachex
[memcachex hexdocs]: https://hexdocs.pm/memcachex/readme.html
[api memcached code]: https://github.com/mbta/api/blob/5863e82aec29f7b7fe5e13e39b2e0e39339df52d/apps/api_web/lib/api_web/rate_limiter/memcache/supervisor.ex
[api rate limiter modules]: https://github.com/mbta/api/tree/5863e82aec29f7b7fe5e13e39b2e0e39339df52d/apps/api_web/lib/api_web/rate_limiter
[memcached commands doc]: https://github.com/memcached/memcached/wiki/Commands
[data structure diagram]: /docs/assets/screens_by_alert_cached_data_structure.png
