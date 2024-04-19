# Migrates `solari` screens to `busway_v2` screens. The new screens have the
# IDs of the old screens with "-V2" appended, leaving the old screens as-is.
# New screens are overwritten if they already exist. The output is the entire
# updated configuration file.
#
# Usage:
#   jq -f scripts/busway-config-migrate.jq priv/local.json > priv/new.json

.screens += (
  .screens | with_entries(
    .value.app_params as $params
    | select(.value.app_id == "solari")
    | select(.value.disabled == false)
    | select($params.overhead == false)
    | {
      key: "\(.key)-V2",
      value: (.value + {
        app_id: "busway_v2",
        app_params: {
          header: { stop_name: $params.station_name },
          evergreen_content: [],
          departures: {
            sections: [
              $params.sections[] | {
                header: {
                  # v1 has the field `section_headers`, which if set to "none"
                  # prevents headers from appearing visually even when a title
                  # is defined for sections (and in that case the title still
                  # provides the audio readout for the header if no alternate
                  # readout is given). In v2 it is just the presence of a title
                  # that determines whether a section has a visual header. This
                  # also means a value for `read_as` is required to read out a
                  # header with no visual title.
                  title: (
                    if $params.section_headers == "none" or .name == "" then
                      null
                    else
                      .name
                    end
                  ),
                  arrow: (
                    if $params.section_headers == "none" then
                      null
                    else
                      .arrow
                    end
                  ),
                  read_as: (
                    .audio.wayfinding as $wayfinding
                    | (
                        if $params.section_headers == "none" then
                          $wayfinding // .name
                        elif $wayfinding != .name and $wayfinding != "" then
                          $wayfinding
                        else
                          null
                        end
                      ) as $read_as
                    | if $read_as == $params.station_name then
                        # Cut some redundant audio from v1 configs where the
                        # first section is given the same title as the screen
                        # itself, which is also read out.
                        null
                      else
                        $read_as
                      end
                  )
                },
                query,
                filters: {
                  max_minutes: .layout | (
                    if .type == "bidirectional" or
                        .opts.max_minutes == "infinity" then
                      null
                    else
                      .opts.max_minutes
                    end
                  ),
                  # NOTE: In the old filter format, `direction_id` must be only
                  # one of the two directions; in the new format, it is allowed
                  # to be `null`, indicating both directions. We should manually
                  # combine instances of "route X dir 0" + "route X dir 1".
                  route_directions: .layout | (
                    if .type == "upcoming" and
                        .opts.routes.route_list != [] then
                      .opts.routes | {
                        action,
                        targets: [
                          .route_list[]
                          | { route_id: .route, direction_id }
                        ]
                      }
                    else
                      null
                    end
                  )
                },
                layout: (
                  if .layout.type == "upcoming" then
                    # NOTE: The v1 config cannot specify a base and max size
                    # separately; `visible_rows` (if Later Departures enabled)
                    # or `num_rows` (if not) fills both roles. This sometimes
                    # means extra space on the screen goes unused. We should
                    # manually change `max` to `null` on sections where it
                    # makes sense for them to use any extra space available.
                    .layout.opts
                    | (
                        if .paged then
                          # `visible_rows` counts Later Departures as a "row",
                          # but only when it is actually displayed.
                          if .num_rows > .visible_rows then
                            .visible_rows - 1
                          else
                            .visible_rows
                          end
                        else
                          .num_rows
                        end
                      ) as $max
                    | (
                        # Because `num_rows` includes departures shown in the
                        # paging area, this being greater than `visible_rows` is
                        # a requirement for the paging area to appear.
                        if .num_rows > .visible_rows then .paged else false end
                      ) as $paged
                    | { min: 1, max: $max, base: $max, include_later: $paged }
                  else
                    # Layout is `bidirectional`, which we don't want to shrink
                    # from its expected size of 2 departures.
                    { min: 2, max: null, base: null, include_later: false }
                  end
                ),
                bidirectional: (.layout.type == "bidirectional")
              }
            ]
          }
        }
      })
    }
  )
)
