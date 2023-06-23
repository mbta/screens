# Disruption diagram alternate structure examples

The alternate structure factors out some data (e.g. line color) to the top level, and
leans more on the client to determine the appropriate presentation of symbols, line segments, etc.
rather than directly telling the client what asset to use for each piece of the diagram.

## Example 1: Shuttle from Boston College to Babcock St, screen at Government Center
![image](assets/disruption_diagrams/1.png)

```ts
{
  effect: "shuttle",
  line: "green",
  current_station_slot_index: 11,
  effect_region_slot_index_range: [0, 8],
  slots: [
    {type: "terminal", label_id: "place-lake"},
    {
      label: {full: "South Street", abbrev: "South St"},
      show_symbol: true
    },
    {
      label: {full: "Chestnut Hill Avenue", abbrev: "Chestnut Hill Ave"},
      show_symbol: true
    },
    {
      label: {full: "Chiswick Road", abbrev: "Chiswick Rd"},
      show_symbol: true
    },
    {
      label: "…",
      show_symbol: false
    },
    {
      label: {full: "Griggs Street", abbrev: "Griggs St"},
      show_symbol: true
    },
    {
      label: {full: "Harvard Avenue", abbrev: "Harvard Ave"},
      show_symbol: true
    },
    {
      label: {full: "Packard's Corner", abbrev: "Packard's Cn"},
      show_symbol: true
    },
    {
      label: {full: "Babcock Street", abbrev: "Babcock St"},
      show_symbol: true
    },
    {
      label: {full: "… via Copley & Kenmore", abbrev: "… via Copley & Kenmore"},
      show_symbol: false
    },
    {
      label: {full: "Park Street", abbrev: "Park St"},
      show_symbol: true
    },
    {type: "terminal", label_id: "place-gover"}
  ]
}
```

- - -

## Example 2: Suspension from Charles/MGH to South Station, screen at Charles/MGH
![image](assets/disruption_diagrams/2.png)

(Correction: The first "Downtown Crossing" label should be "Kendall/MIT")

```ts
{
  effect: "suspension",
  line: "red",
  current_station_slot_index: 2,
  effect_region_slot_index_range: [3, 4],
  slots: [
    {type: "arrow", label_id: "place-alfcl"},
    {
      label: {full: "Kendall/MIT", abbrev: "Kendall/MIT"},
      show_symbol: true
    },
    {
      label: {full: "Charles/MGH", abbrev: "Charles/MGH"},
      show_symbol: true
    },
    {
      label: {full: "Park Street", abbrev: "Park St"},
      show_symbol: true
    },
    {
      label: {full: "Downtown Crossing", abbrev: "Downt'n Xng"},
      show_symbol: true
    },
    {
      label: {full: "South Station", abbrev: "South Sta"},
      show_symbol: true
    },
    {type: "arrow", label_id: "place-asmnl+place-brntn"}
  ]
}
```

- - -

## Example 3: Station closure at Kent St and St. Mary's St, screen at Government Center
![image](assets/disruption_diagrams/3.png)

```ts
{
  effect: "station_closure",
  line: "green",
  current_station_slot_index: 11,
  closed_station_slot_indices: [2, 4],
  slots: [
    {type: "arrow", label_id: "place-clmnl"},
    {
      label: {full: "Saint Paul Street", abbrev: "St. Paul St"},
      show_symbol: true
    },
    {
      label: {full: "Kent Street", abbrev: "Kent St"},
      show_symbol: true
    },
    {
      label: {full: "Hawes Street", abbrev: "Hawes St"},
      show_symbol: true
    },
    {
      label: {full: "Saint Mary's Street", abbrev: "St. Mary's"},
      show_symbol: true
    },
    {
      label: {full: "Kenmore", abbrev: "Kenmore"},
      show_symbol: true
    },
    {
      label: {full: "Hynes Convention Center", abbrev: "Hynes"},
      show_symbol: true
    },
    {
      label: {full: "Copley", abbrev: "Copley"},
      show_symbol: true
    },
    {
      label: {full: "Arlington", abbrev: "Arlington"},
      show_symbol: true
    },
    {
      label: {full: "Boylston", abbrev: "Boylston"},
      show_symbol: true
    },
    {
      label: {full: "Park Street", abbrev: "Park St"},
      show_symbol: true
    },
    {type: "terminal", label_id: "place-gover"}
  ]
}
```
