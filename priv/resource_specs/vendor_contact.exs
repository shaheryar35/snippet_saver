# mix gen.resource Phase 2 validation spec — embedded-only child.
#
# `vendor_contact` is the child half of the Phase 2 smoke test: a `routing :embedded_only`
# resource (design doc §9.4) that gets schema/migration/context/fixtures/test but no web layer at
# all — it's only ever consumed via the `vendor_contacts` nested_collection on `vendor.exs`.
#
# `belongs_to :vendor, ..., dropdown: false` is the plain internal FK back to the parent (design
# doc §5) — never rendered as a form field (there's no generated form for an embedded-only
# resource in the first place), mirroring the codebase's own `field :patient_id, :id` convention
# on `PatientMasterProblem`/`PatientNote`. `table: :vendors` is required here too:
# `SnippetSaver.Catalog.Vendor` doesn't exist yet at this point (it's generated *after* this spec,
# per the ordering note below), so the migration can't introspect its table name the normal way.
#
# Deliberately NOT `required: true` here (unlike the hand-written PatientNote/PatientMasterProblem
# precedent it otherwise mirrors) — that's a known Phase 2 gap, not an oversight: the generated
# fixture/test suite for this resource has no way to auto-populate a required FK to a parent that
# doesn't exist yet at generation time (no `options_from` to pick an existing row from), so
# `vendor_contact_fixture()` would fail its own required-field validation with no attrs supplied.
# In real usage this FK is always populated anyway — every row that reaches `create_vendor_contact/1`
# goes through `Vendor`'s `replace_vendor_contacts/2` sync function, which always sets `vendor_id`
# explicitly. Making the generator handle "required + unpopulatable" fixtures/tests cleanly is
# follow-up work, not solved by this spec.
#
# Run this spec BEFORE vendor.exs — vendor.exs's nested_collection references
# `SnippetSaver.Catalog.VendorContact` as an already-compiled module (see
# `SnippetSaver.ResourceGen.Naming.nc_child_plural/1`).

import SnippetSaver.ResourceGen.Spec

resource "vendor_contact" do
  table :vendor_contacts
  context SnippetSaver.Catalog
  audit false
  soft_delete false
  routing :embedded_only

  belongs_to :vendor, SnippetSaver.Catalog.Vendor, dropdown: false, table: :vendors

  field :name, :text, required: true
  field :role, :text
end
