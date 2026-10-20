defmodule Screens.Repo.Migrations.BackfillWayfindingInfo do
  use Ecto.Migration

  @doc"""
  Update `screen_configs#config` tables for scheduled wayfinding information.

  Each `section` object in `app_params.departures.sections` is modified depending on the contents
  of each object.
  1. If the object's `image_path` field is `null`, an empty string, or does not exist:
      1. Create a `wayfinding_information` field on the `section` object, initialize it to `null`
      2. Remove the `image_path` field (if it exists)
  2. If the object's `image_path` field is a non-empty string:
      1. Create a `wayfinding_information` field on the `section` object
      2. Initialize the following fields on `wayfinding_information`:
          -  `image_path` is initialized using the section's existing `image_path` value
          -  `read_as: null`
          -  `schedule: [end_dt: null, start_dt: null]`
          -  `wayfinding_point` is initialized using the section's existing `wayfinding_point` value
      3. Delete the section's `image_path` and `wayfinding_point` fields
  """
  def up do
    execute("""
    UPDATE screen_configs
    SET config = jsonb_set(
      config,
      '{app_params,departures,sections}',
      (
        SELECT COALESCE(
          jsonb_agg(
            CASE
              WHEN jsonb_typeof(section -> 'header') = 'object'
                   AND jsonb_typeof(section #> '{header,wayfinding_information}')
                       IS DISTINCT FROM 'object'
              THEN
                jsonb_set(
                  section,
                  '{header}',
                  ((section -> 'header') - 'image_path' - 'wayfinding_point')
                  || jsonb_build_object(
                    'wayfinding_information',
                    CASE
                      WHEN jsonb_typeof(section #> '{header,image_path}') = 'string'
                        AND section #>> '{header,image_path}' <> ''
                      THEN
                        jsonb_build_object(
                          'image_path', section #> '{header,image_path}',
                          'read_as', 'null'::jsonb,
                          'schedule', jsonb_build_array(
                              jsonb_build_object(
                                  'start_dt', 'null'::jsonb,
                                  'end_dt', 'null'::jsonb
                              )
                          ),
                          'wayfinding_point',
                          COALESCE(section #> '{header,wayfinding_point}', 'null'::jsonb)
                        )
                      ELSE 'null'::jsonb
                    END
                  )
                )
              ELSE section
            END
            ORDER BY position
          ),
          '[]'::jsonb
        )
        FROM jsonb_array_elements(config #> '{app_params,departures,sections}')
          WITH ORDINALITY AS sections(section, position)
      )
    )
    WHERE jsonb_typeof(config #> '{app_params,departures,sections}') = 'array'
    """)
  end

  @doc"""
  Update `screen_configs#config` tables to remove scheduled wayfinding information.

  Each `section` object in `app_params.departures.sections` is modified depending on the contents
  of each object.
  1. It recreates the object's `image_path` field with the value stored in
  `wayfinding_information#image_path`. Defaults to `null` if no value is present.
  2. It recreates the object's `wayfinding_point` field with the value stored in
  `wayfinding_information#wayfinding_point`. Defaults to `null` if no value is present.
  3. It removes the `wayfinding_information` field on the `section` object.
  """
  def down do
    execute("""
    UPDATE screen_configs
    SET config = jsonb_set(
      config,
      '{app_params,departures,sections}',
      (
        SELECT COALESCE(
          jsonb_agg(
            CASE
              WHEN jsonb_typeof(section -> 'header') = 'object' THEN
                jsonb_set(
                  section,
                  '{header}',
                  CASE
                    WHEN jsonb_typeof(section #> '{header,wayfinding_information}') = 'object' THEN
                      ((section -> 'header') - 'wayfinding_information')
                      || jsonb_build_object(
                        'image_path',
                        COALESCE(
                          section #> '{header,wayfinding_information,image_path}',
                          'null'::jsonb
                        ),
                        'wayfinding_point',
                        COALESCE(
                          section #> '{header,wayfinding_information,wayfinding_point}',
                          'null'::jsonb
                        )
                      )
                    ELSE
                      '{"image_path": null, "wayfinding_point": null}'::jsonb
                      || ((section -> 'header') - 'wayfinding_information')
                  END
                )
              ELSE section
            END
            ORDER BY position
          ),
          '[]'::jsonb
        )
        FROM jsonb_array_elements(config #> '{app_params,departures,sections}')
          WITH ORDINALITY AS sections(section, position)
      )
    )
    WHERE jsonb_typeof(config #> '{app_params,departures,sections}') = 'array'
    """)
  end
end
