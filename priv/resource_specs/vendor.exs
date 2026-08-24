# mix gen.resource Phase 2 validation spec — top-level parent with a `:buffered` nested_collection.
#
# Pairs with `vendor_contact.exs` (the `routing :embedded_only` child, generated first). Neither
# name collides with any hand-built module or anything Phase 1 already generated (`hear_about_option`/
# `SnippetSaver.Catalog.HearAboutOption`) — same diligence Phase 1 applied when it swapped away from
# `AppointmentType`.
#
# `mode: :buffered` is the one exercised end-to-end here (generate, migrate, browser click-through):
# adding/editing/deleting `vendor_contacts` rows in the modal only touches in-memory socket state
# (`@vendor_contacts_rows`) until the vendor record itself is saved, at which point
# `replace_vendor_contacts/2` (generated into `SnippetSaver.Catalog` alongside the rest of this
# spec's context functions) deletes-and-reinserts the full row set in one transaction — mirroring
# `Patients.replace_patient_master_problems/2`.

import SnippetSaver.ResourceGen.Spec

resource "vendor" do
  table :vendors
  context SnippetSaver.Catalog
  audit true
  soft_delete true
  routing :top_level

  field :company_name, :text, required: true

  nested_collection :vendor_contacts,
    mode: :buffered,
    child_schema: SnippetSaver.Catalog.VendorContact,
    row_fields: [:name, :role],
    sync_fn: {SnippetSaver.Catalog, :replace_vendor_contacts}

  list_fields [company_name: [sortable: true, filterable: true]]

  subtabs [:details]
end
