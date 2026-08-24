# mix gen.resource Phase 1 validation spec.
#
# Deviates from the design doc's own suggested "appointment_type" example: that name collides
# with the already hand-built `SnippetSaver.Settings.AppointmentType` (schema, context functions,
# migration, and LiveView all already exist). Generating over it would either violate "no changes
# to already-hand-built modules" or fail outright (duplicate table/functions). `hear_about_option`
# is a genuinely new, flat, top-level catalog resource: `Contact.hear_about_option_id` already
# exists as a plain integer column with nothing backing it yet (see
# lib/snippet_saver/contacts/contact.ex), so this is also a real, useful resource to generate.
#
# Uses a new `SnippetSaver.Catalog` context (rather than `SnippetSaver.Settings`) for the same
# reason — appending into the hand-built `settings.ex`/`settings_test.exs`/`settings_fixtures.ex`
# would touch already-hand-built files. A brand-new context avoids that entirely for this smoke
# test; the generator's append-with-marker path is still real code, just not exercised by this
# particular run (see design doc §9.1 and the Planner's `append_mode/1`).

import SnippetSaver.ResourceGen.Spec

resource "hear_about_option" do
  table :hear_about_options
  context SnippetSaver.Catalog
  audit true
  soft_delete true
  routing :top_level

  field :name, :text, required: true
  field :is_active, :boolean, required: true, default: true
  field :category, :select,
    options: [{"Referral", "referral"}, {"Online", "online"}, {"Other", "other"}]

  list_fields [
    name: [sortable: true, filterable: true],
    is_active: [sortable: true, filterable: false],
    category: [sortable: true, filterable: true]
  ]

  subtabs [:details]
end
