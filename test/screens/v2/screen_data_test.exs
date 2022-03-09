defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  alias Screens.V2.ScreenData
  alias Screens.V2.WidgetInstance.MockWidget

  describe "pick_instances/2" do
    test "chooses the expected template and instance placement" do
      candidate_template =
        {:flex_zone,
         %{
           one_large: [:large],
           two_medium: [:medium_left, :medium_right],
           one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right]
         }}

      smalls = [:small_upper_right, :small_lower_right]
      mediums = [:medium_left, :medium_right]

      candidate_instances = [
        %MockWidget{slot_names: smalls, priority: [4], content: "4"},
        %MockWidget{slot_names: smalls, priority: [1], content: "1"},
        %MockWidget{slot_names: mediums, priority: [3], content: "3"},
        %MockWidget{slot_names: smalls, priority: [2], content: "2"}
      ]

      {actual_layout, actual_instance_placement} =
        ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:flex_zone,
              {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]}} ==
               actual_layout

      assert %{
               medium_left: %MockWidget{content: "3"},
               small_lower_right: %MockWidget{content: "2"},
               small_upper_right: %MockWidget{content: "1"}
             } = actual_instance_placement
    end

    test "handles paged regions correctly, and places higher-priority instances in earlier pages" do
      candidate_template =
        {:screen,
         %{
           normal: [
             :header,
             {{0, :flex_zone},
              %{
                one_large: [{0, :large}],
                two_medium: [{0, :medium_left}, {0, :medium_right}],
                one_medium_two_small: [
                  {0, :medium_left},
                  {0, :small_upper_right},
                  {0, :small_lower_right}
                ]
              }},
             {{1, :flex_zone},
              %{
                one_large: [{1, :large}],
                two_medium: [{1, :medium_left}, {1, :medium_right}],
                one_medium_two_small: [
                  {1, :medium_left},
                  {1, :small_upper_right},
                  {1, :small_lower_right}
                ]
              }}
           ],
           takeover: [:full_screen]
         }}

      smalls = [:small_upper_right, :small_lower_right]
      mediums = [:medium_left, :medium_right]

      candidate_instances = [
        %MockWidget{slot_names: smalls, priority: [4], content: "4"},
        %MockWidget{slot_names: smalls, priority: [1], content: "1"},
        %MockWidget{slot_names: mediums, priority: [3], content: "3"},
        %MockWidget{slot_names: smalls, priority: [2], content: "2"},
        %MockWidget{slot_names: [:large], priority: [2], content: "5"},
        %MockWidget{slot_names: [:header], priority: [2], content: "header"}
      ]

      {actual_layout, actual_instance_placement} =
        ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:screen,
              {:normal,
               [
                 :header,
                 {{0, :flex_zone},
                  {:one_medium_two_small,
                   [{0, :medium_left}, {0, :small_upper_right}, {0, :small_lower_right}]}},
                 {{1, :flex_zone}, {:one_large, [{1, :large}]}}
               ]}} == actual_layout

      assert %{
               :header => %MockWidget{content: "header"},
               {0, :medium_left} => %MockWidget{content: "3"},
               {0, :small_lower_right} => %MockWidget{content: "2"},
               {0, :small_upper_right} => %MockWidget{content: "1"},
               {1, :large} => %MockWidget{content: "5"}
             } = actual_instance_placement
    end

    test "prefers to place as many instances as possible, priority allowing" do
      candidate_template =
        {:screen,
         %{
           normal_flex_zone: [
             {{0, :flex_zone}, %{one_large: [{0, :large}]}},
             {{1, :flex_zone}, %{one_large: [{1, :large}]}}
           ],
           takeover_flex_zone: [:large_takeover]
         }}

      # We expect the high-priority instance to be placed in the first page rather than
      # the takeover slot, because that allows the second widget to be placed.
      candidate_instances = [
        %MockWidget{slot_names: [:large], priority: [2], content: "2"},
        %MockWidget{slot_names: [:large_takeover, :large], priority: [1], content: "1"}
      ]

      {actual_layout, actual_instance_placement} =
        ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:screen,
              {:normal_flex_zone,
               [
                 {{0, :flex_zone}, {:one_large, [{0, :large}]}},
                 {{1, :flex_zone}, {:one_large, [{1, :large}]}}
               ]}} == actual_layout

      assert %{{0, :large} => %MockWidget{content: "1"}, {1, :large} => %MockWidget{content: "2"}} =
               actual_instance_placement
    end

    test "fills earlier pages first" do
      candidate_template =
        {:screen,
         %{
           normal: [
             {{0, :paged_content1}, %{one_large: [{0, :content1_large}]}},
             {{1, :paged_content1}, %{one_large: [{1, :content1_large}]}},
             {{0, :paged_content2}, %{one_large: [{0, :content2_large}]}},
             {{1, :paged_content2}, %{one_large: [{1, :content2_large}]}}
           ]
         }}

      candidate_instances = [
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [2], content: "2"},
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [1], content: "1"},
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [4], content: "4"},
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [3], content: "3"}
      ]

      {actual_layout, actual_instance_placement} =
        ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:screen,
              {:normal,
               [
                 {{0, :paged_content1}, {:one_large, [{0, :content1_large}]}},
                 {{1, :paged_content1}, {:one_large, [{1, :content1_large}]}},
                 {{0, :paged_content2}, {:one_large, [{0, :content2_large}]}},
                 {{1, :paged_content2}, {:one_large, [{1, :content2_large}]}}
               ]}} == actual_layout

      assert %{
               {0, :content1_large} => %MockWidget{content: "1"},
               {0, :content2_large} => %MockWidget{content: "2"},
               {1, :content1_large} => %MockWidget{content: "3"},
               {1, :content2_large} => %MockWidget{content: "4"}
             } = actual_instance_placement
    end

    test "filters out blank pages" do
      candidate_template =
        {:screen,
         %{
           normal: [
             :header,
             {{0, :flex_zone},
              %{
                one_large: [{0, :large}],
                two_medium: [{0, :medium_left}, {0, :medium_right}],
                one_medium_two_small: [
                  {0, :medium_left},
                  {0, :small_upper_right},
                  {0, :small_lower_right}
                ]
              }},
             {{1, :flex_zone},
              %{
                one_large: [{1, :large}],
                two_medium: [{1, :medium_left}, {1, :medium_right}],
                one_medium_two_small: [
                  {1, :medium_left},
                  {1, :small_upper_right},
                  {1, :small_lower_right}
                ]
              }}
           ],
           takeover: [:full_screen]
         }}

      candidate_instances = [
        %MockWidget{slot_names: [:large], priority: [2], content: "1"},
        %MockWidget{slot_names: [:header], priority: [2], content: "header"}
      ]

      {actual_layout, actual_instance_placement} =
        ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:screen,
              {:normal,
               [
                 :header,
                 {{0, :flex_zone}, {:one_large, [{0, :large}]}}
               ]}} == actual_layout

      assert %{
               :header => %MockWidget{content: "header"},
               {0, :large} => %MockWidget{content: "1"}
             } = actual_instance_placement
    end
  end

  describe "serialize/1" do
    test "serializes a hierarchical layout" do
      layout =
        {:screen,
         {:normal,
          [
            :main_content,
            {:flex_zone, {:two_medium, [:medium_left, :medium_right]}},
            :footer
          ]}}

      selected_widgets = %{
        main_content: %MockWidget{
          slot_names: [:main_content],
          widget_type: :departures,
          content: []
        },
        medium_left: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "face_covering.png"
        },
        medium_right: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "autopay.png"
        },
        footer: %MockWidget{
          slot_names: [:footer],
          widget_type: :normal_footer,
          content: "fare info"
        }
      }

      paging_metadata = %{flex_zone: {1, 3}, footer: {0, 2}}

      expected = %{
        data: %{
          type: :normal,
          main_content: %{type: :departures, content: []},
          flex_zone: %{
            type: :two_medium,
            page_index: 1,
            num_pages: 3,
            medium_left: %{type: :static_image, content: "face_covering.png"},
            medium_right: %{type: :static_image, content: "autopay.png"}
          },
          footer: %{type: :normal_footer, page_index: 0, num_pages: 2, content: "fare info"}
        },
        force_reload: false,
        disabled: false
      }

      assert expected == ScreenData.serialize({layout, selected_widgets, paging_metadata})
    end
  end

  describe "resolve_paging/3" do
    test "chooses pages based on current time; condenses layout and widget map accordingly" do
      layout =
        {:screen,
         {:normal,
          [
            :header,
            {{0, :flex_zone},
             {:one_medium_two_small,
              [{0, :medium_left}, {0, :small_upper_right}, {0, :small_lower_right}]}},
            {{1, :flex_zone}, {:one_large, [{1, :large}]}}
          ]}}

      selected_widgets = %{
        :header => %MockWidget{slot_names: [], widget_type: :header, content: "header"},
        {0, :medium_left} => %MockWidget{
          slot_names: [],
          widget_type: :subway_status,
          content: "3"
        },
        {0, :small_lower_right} => %MockWidget{slot_names: [], widget_type: :alert, content: "2"},
        {0, :small_upper_right} => %MockWidget{slot_names: [], widget_type: :alert, content: "1"},
        {1, :large} => %MockWidget{slot_names: [], widget_type: :psa, content: "5"}
      }

      refresh_rate = 15
      now = ~U"2021-01-01T00:00:16Z"

      expected_layout =
        {:screen,
         {:normal,
          [
            :header,
            {:flex_zone, {:one_large, [:large]}}
          ]}}

      expected_paging_metadata = %{flex_zone: {1, 2}}

      assert {^expected_layout,
              %{
                header: %MockWidget{widget_type: :header, content: "header"},
                large: %MockWidget{widget_type: :psa, content: "5"}
              },
              ^expected_paging_metadata} =
               ScreenData.resolve_paging({layout, selected_widgets}, refresh_rate, now)
    end

    test "chooses pages independently for each paged region, and handles paged regions rooted deeper in the layout" do
      layout =
        {:screen,
         {:normal,
          [
            {{0, :header}, {:time_header, [{0, :header_text}, {0, :time}]}},
            {{1, :header}, {:weather_header, [{1, :header_text}, {1, :weather}]}},
            {:main_content,
             {:normal_main_content,
              [
                :departures,
                {{0, :flex_zone},
                 {:one_medium_two_small,
                  [{0, :medium_left}, {0, :small_upper_right}, {0, :small_lower_right}]}},
                {{1, :flex_zone}, {:one_large, [{1, :large}]}},
                {{2, :flex_zone}, {:two_medium, [{2, :medium_left}, {2, :medium_right}]}}
              ]}},
            {0, :footer},
            {1, :footer}
          ]}}

      selected_widgets = %{
        {0, :header_text} => %MockWidget{slot_names: [], content: "header_text 0"},
        {0, :time} => %MockWidget{slot_names: [], content: "time"},
        {1, :header_text} => %MockWidget{slot_names: [], content: "header_text 1"},
        {1, :weather} => %MockWidget{slot_names: [], content: "weather"},
        :departures => %MockWidget{slot_names: [], content: "departures"},
        {0, :medium_left} => %MockWidget{slot_names: [], content: "medium_left 0"},
        {0, :small_upper_right} => %MockWidget{slot_names: [], content: "small_upper_right"},
        {0, :small_lower_right} => %MockWidget{slot_names: [], content: "small_lower_right"},
        {1, :large} => %MockWidget{slot_names: [], content: "large"},
        {2, :medium_left} => %MockWidget{slot_names: [], content: "medium_left 1"},
        {2, :medium_right} => %MockWidget{slot_names: [], content: "medium_right"},
        {0, :footer} => %MockWidget{slot_names: [], content: "footer 0"},
        {1, :footer} => %MockWidget{slot_names: [], content: "footer 1"}
      }

      # We expect page index = 0 for regions with 2 pages,
      #           page index = 2 for regions with 3 pages.
      refresh_rate = 15
      now = ~U"2021-01-01T00:00:32Z"

      expected_layout =
        {:screen,
         {:normal,
          [
            {:header, {:time_header, [:header_text, :time]}},
            {:main_content,
             {:normal_main_content,
              [:departures, {:flex_zone, {:two_medium, [:medium_left, :medium_right]}}]}},
            :footer
          ]}}

      expected_paging_metadata = %{header: {0, 2}, flex_zone: {2, 3}, footer: {0, 2}}

      assert {^expected_layout,
              %{
                header_text: %MockWidget{slot_names: [], content: "header_text 0"},
                time: %MockWidget{slot_names: [], content: "time"},
                departures: %MockWidget{slot_names: [], content: "departures"},
                medium_left: %MockWidget{slot_names: [], content: "medium_left 1"},
                medium_right: %MockWidget{slot_names: [], content: "medium_right"},
                footer: %MockWidget{slot_names: [], content: "footer 0"}
              },
              ^expected_paging_metadata} =
               ScreenData.resolve_paging({layout, selected_widgets}, refresh_rate, now)
    end
  end

  describe "sorted_slot_list_intersection/2" do
    test "returns the intersection of two non-paged slot lists" do
      template_slots = [
        :normal_header,
        :departures,
        :medium_left,
        :small_upper_right,
        :small_lower_right,
        :normal_footer
      ]

      instance_slots = [:small_upper_right, :small_lower_right, :departures]

      expected = [:departures, :small_upper_right, :small_lower_right]

      assert expected == ScreenData.sorted_slot_list_intersection(template_slots, instance_slots)
    end

    test "matches instance slots with all corresponding paged template slots" do
      template_slots = [
        {0, :medium_left},
        {0, :medium_right},
        {1, :medium_left},
        {1, :medium_right}
      ]

      instance_slots = [:medium_right]

      expected = [{0, :medium_right}, {1, :medium_right}]

      assert expected == ScreenData.sorted_slot_list_intersection(template_slots, instance_slots)
    end

    test "sorts paged slots by their page index and prioritizes non-paged content" do
      template_slots = [
        :normal_header,
        :region_x,
        {0, :region1},
        {1, :region1},
        :divider,
        {0, :region2},
        {1, :region2},
        :normal_footer
      ]

      instance_slots = [:divider, :normal_header, :region_y, :region1, :region2, :normal_footer]

      expected = [
        :normal_header,
        :divider,
        :normal_footer,
        {0, :region1},
        {0, :region2},
        {1, :region1},
        {1, :region2}
      ]

      assert expected == ScreenData.sorted_slot_list_intersection(template_slots, instance_slots)
    end
  end
end
