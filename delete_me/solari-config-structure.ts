// Solari config is complicated and deeply nested.
//
// There are opportunities to remove some fields entirely given the less
// customizable Busway app spec. E.g. `.psa_config`.
//
// Some nesting levels can also be collapsed--there are a few cases of objects
// with only one field, where we had expected to add more fields later on but
// never did. E.g. `.sections[].query.opts`.

interface Solari {
  // Text used for the screen's header.
  station_name: string;
  // True if this screen is mounted overhead.
  //
  // Currently used only for Solari screens at Nubian. Overhead screens get
  // larger type size to adhere to ADA min type size guidelines. Their departure
  // rows also do an animated "swap out" between predicted arrival time and
  // crowding level, since there isn't enough width to show both alongside the
  // larger headsign type size.
  overhead: boolean;
  // Indicates how section headers (aka "wayfinding") should be displayed.
  //
  // Since we are no longer supporting the "vertical" style, this can be
  // removed. Header can be added/omitted on a per-section basis, based on the
  // value of `section.name` and `section.arrow`.
  section_headers: SectionHeadersStyle;
  // Per-section configuration.
  sections: Section[];
  // Old configuration for scheduled PSAs / manual takeover content.
  // This is replaced by "evergreen content" configuration (and widget) and
  // can be omitted from the new config.
  psa_config: PsaConfig;
  // Ditto.
  audio_psa: AudioPsa;
}

interface Section {
  // Text used for the section's header.
  name: string;
  // Wayfinding arrow displayed on the right end of the section's header.
  arrow: Arrow | null;
  // Specifies how to fetch data for this section from the v3 API.
  query: Query;
  // Specifies how to present the fetched data.
  layout: Layout;
  // Configuration for the on-demand audio readout of the screen.
  audio: Audio;
  // A case of "naming is hard". This is used to categorize the section.
  // A mix of route / line / mode.
  // Used here: lib/screens/solari_screen_data.ex:99
  // as well as on the client to draw a route pill representative of the section
  // in failure layouts.
  pill: Pill;
  // Headway mode configuration. Used by the server to determine whether section
  // is in headway mode.
  headway: Headway;
}

// Specified as a compass direction. E.g. "n" produces an arrow pointing toward
// the top of the screen, "e" to the right, etc.
type Arrow = "n" | "e" | "s" | "w" | "ne" | "se" | "sw" | "nw";

interface Query {
  // Parameters (mostly filters) to be used in the v3 API predictions query for
  // this section.
  params: QueryParams;
  // Additional options, besides those that translate directly to v3 API filters.
  opts: QueryOpts;
}

interface QueryParams {
  // Filter predictions to these stops:
  stop_ids: string[];
  // Filter predictions to these routes:
  route_ids: string[];
  // Filter predictions to this direction (or don't filter by direction):
  direction_id: 0 | 1 | "both";
  // Filter predictions to routes of this type (or don't filter by route type):
  route_type: RouteType | null;
}

interface QueryOpts {
  // If true, also fetch schedules for this section (reusing the same query
  // params) and pair predictions with their corresponding schedules.
  //
  // Used for CR sections. Upcoming trips that are further out and do not yet
  // have predictions, get shown with their scheduled times instead.
  //
  // Value is read here: lib/screens/departures/departure.ex:57
  // Only schedules that lack a corresponding prediction are kept: lib/screens/departures/departure.ex:181
  include_schedules: boolean;
}

type Layout = Bidirectional | Upcoming;

// Section shows the nearest prediction in each direction. This naturally limits
// the section to 2 rows max.
interface Bidirectional {
  // Note: For all but one bidirectional section in current config, this field
  // is set to a value that results in a no-op. The one place it's used is a
  // "show-off" screen right outside 10PP--not a serious use of the app.
  //
  // We may be able to reduce the bidirectional layout config to have no
  // additional fields.
  routes: RouteConfig;
}

// "Normal" layout. The section shows as many upcoming predictions as space allows.
interface Upcoming {
  // Limits the maximum number of departures to show in the section.
  num_rows: number | "infinity";
  // If true, a "Later Departures" row is shown at the bottom of the section
  // when there are more predictions than it can fit.
  paged: boolean;
  // This field is only used by, and only takes effect for, paged sections.
  // (Sections with "Later Departures" at the end)
  //
  // This field works in tandem with `num_rows`.
  // In paged sections, `num_rows` limits the maximum number of _departures_ to
  // keep in the JS array for that section.
  // Whereas `visible_rows` limits the number of _rendered rows_ drawn on the
  // page, with the "Later Departures" element counting as 1 row.
  // For example if a section has `visible_rows: 3` and a lot of departures to
  // show, then it will render 2 regular departure rows and then put up to 5
  // additional departures into the "Later Departures" element.
  //
  // One very funky piece of behavior is that when there are 2 or more sections
  // that need to have rows removed to fit everything on the screen, the
  // auto-sizing code attempts to maintain the **ratio** of visible rows between
  // those sections.
  // For example, if there are two sections with `visible_rows` of 2 and 10
  // respectively, and we need to cut the content down to 6 rows total, then we
  // will end up with sections containing 1 and 5 rows respectively--the
  // proportions are maintained.
  visible_rows: number | "infinity";
  // Additional filters on the prediction rows. See `RouteConfig` interface below.
  routes: RouteConfig;
  // Additional filter on the prediction rows. Predictions more than
  // `max_minutes` minutes in the future are removed.
  //
  // This should probably be moved to Query config along with `routes`.
  max_minutes: number | "infinity";
}

// An additional filter on which routes to include/exclude in the section.
// Mostly used in bus sections.
//
// Usage examples in config: MUL-102, MUL-104, MUL-107, MUL-108, MUL-111
//
// This seems like it could be moved over to the Query config. It's not
// completely pointless, as it allows more fine-tuned filtering than what you
// can do in one v3 API predictions query, but it doesn't belong in the Layout
// config.
interface RouteConfig {
  action: "include" | "exclude";
  route_list: RouteDescriptor[];
}

interface RouteDescriptor {
  route: string;
  direction_id: 0 | 1;
}

interface Audio {
  // Name to for the section, used in the audio readout. This is the audio
  // equivalent of `section.name`. (There were enough discrepancies between
  // visual & audio section names that we decided to define them separately.)
  wayfinding: string | null;
}

interface Headway {
  // These two fields are used to look up appropriate piece of Signs UI config
  // that specifies headways for this route/direction/track segment.
  sign_ids: string[];
  headway_id: string;
  // Headsigns to display in the message when headway mode is active.
  headsigns: string[];
}

type RouteType = "light_rail" | "subway" | "rail" | "bus" | "ferry";

type Pill =
  | "bus"
  | "red"
  | "orange"
  | "green"
  | "blue"
  | "cr"
  | "mattapan"
  | "silver";

/*
 * -----------------------------------------------
 * The following types are N/A for the Busway app.
 * -----------------------------------------------
 */
type SectionHeadersStyle =
  // Headers use horizontal text and take up the full width of the screen.
  | "normal"
  // Headers use vertical text and display along the left edge of the screen. Used only on MUL-105, not supported in Busway app.
  | "vertical"
  // Sections do not get any headers. Sections are separated by a slightly thicker line than the one used between departures.
  | "none";

interface PsaConfig {}
interface AudioPsa {}
