# Resource Generator DSL — Design Document

## 1. Purpose

SnippetSaver currently builds every module (Contacts, Patients, Employees) by hand-writing the
same repeating shape: an Ecto schema, a context with CRUD functions, a `FormComponent`, an
`IndexView`, subtab routing, and a JS tab hook. This is proven and working, but fully manual —
each new module means re-deriving the same pattern from scratch (or from a written spec handed
to Claude Code).

This document defines a **code generator** (`mix gen.resource`) that reads a small declarative
spec file per resource and writes out the boilerplate — real Ecto/Phoenix/HEEx files, not a
runtime abstraction layer. Nothing interprets the spec at request time; once generated, the files
are ordinary code, edited by hand exactly like output from `phx.gen.live` is today.

**Goal for future modules**: define a resource's schema once in a spec file → generate the
mechanical 70-95% of the module → hand-finish the genuinely bespoke parts (custom widgets,
domain-specific layout) → review → migrate → ship.

---

## 2. What the generator is NOT

- Not a framework swap (not Ash, not a new runtime resource layer).
- Not a macro-based DSL that runs in production — the DSL only exists at generation time.
- Not fully automatic for every field — some patterns (nested collections, nested relationships)
  are only partially generatable; the rest is intentionally left as manual work, same as it is
  today for the Notes/Images tabs in the Patient module.

---

## 3. Field type taxonomy

Every form field in the app falls into one of six types. Each has a different generation story.

| # | Type | Example (existing code) | Generation coverage |
|---|------|--------------------------|----------------------|
| 1 | `:text` / `:number` / `:date` / `:textarea` | `code`, `weight`, `date_of_birth` | Fully generated |
| 2 | `:boolean` | `age_estimated`, `bill_to_other` (rendered via `<.yes_no>`) | Fully generated |
| 3 | `:select` (static options) | `sex`, `weight_unit`, `resuscitate` | Fully generated — options declared inline in spec |
| 4 | `:select` (options from a context) | `species_id` (from `Settings.list_species/0`) | Fully generated — spec declares the source function, generator injects the `assign` |
| 5 | `:searchable_select` | `breed_id`, `colour_id`, master-problem-template picker | Fully generated — component call + the ~8 mechanical `handle_event` clauses (focus/search/pick/clear) are templated |
| 6 | `:nested_collection` | Master Problems (buffered), Patient Notes (immediate) | Partially generated — shell + event plumbing generated, row-form field contents hand-composed from types 1-5 |

Build order (highest ROI / lowest risk first): **1 & 2 → 4 → 3 → 5 → 6**.

---

## 4. Relationship field enhancement: quick-create ("+")

Any `belongs_to`-style field (type 4 or 5 above) can optionally support inline creation of the
related record, without leaving the current form.

### Mental model

The user is filling out a form (e.g. Patient) and reaches a relationship field (e.g.
`owner_contact_id`). Instead of only picking from existing records, a `+` button beside the field
opens the **target resource's own existing `FormComponent`** in a modal. On save, the modal form
sends a message back to the parent form (reusing the `parent_pid` / `send(pid, {:x_saved, record,
msg})` convention already used throughout the codebase), the parent auto-fills the field with the
new record's id and display label, and the modal closes.

### Scope: one level deep only

A quick-create modal must not itself offer another quick-create button. Patient → quick-create
Contact is fine. Patient → quick-create Contact → quick-create [something else] is out of scope
for now. If a real future requirement needs a second level, it will be scoped as a deliberate
follow-up, not assumed up front.

### Spec syntax

```elixir
belongs_to :owner_contact, SnippetSaver.Contacts.Contact,
  quick_create: true,
  display_fn: {SnippetSaver.Contacts, :contact_display_name}
```

`display_fn` is required whenever `quick_create: true` is set, because every resource labels
itself differently (Patient uses `patient_name`; Contact composes a name differently) — the
generator has no way to guess this, so the spec must supply it.

### Precondition

This only works when the target resource already has a `FormComponent` that follows the
`parent_pid` notify-on-save convention (whether generated or hand-built). Quick-create cannot
generate two forms at once — it wires a new relationship field to an *existing* form.

---

## 5. Nested collection: two save-timing modes

`:nested_collection` fields (a parent form containing a variable-length list of child rows,
shown as a table + add/edit modal — e.g. Master Problems on the Patient form) must declare a
`mode`, with no implicit default (explicit only, to avoid silently choosing the wrong data-loss
behavior):

### `mode: :buffered`

Child rows are held only in LiveView socket state while the user works. Nothing is written to the
database until the **parent form** is saved — at which point all rows are synced in one
transaction (existing example: `replace_patient_master_problems/2` — delete all existing rows for
the parent, then reinsert the current in-memory list). Cancelling the parent form discards every
unsaved child row; they were never persisted.

Use when the child rows are inseparable from the parent record's own save action.

### `mode: :immediate`

Each child row is saved to the database the moment its own row-form is submitted — independent of
whether the parent form itself has been saved or even touched (existing example: Patient Notes,
via `create_patient_note/2` / `update_patient_note/3` called directly from the modal).

Use when the child record has its own independent lifecycle.

### Spec syntax

```elixir
field :master_problems, :nested_collection,
  mode: :buffered,
  child_schema: SnippetSaver.Patients.PatientMasterProblem,
  row_fields: [:master_problem_template_id, :notes],
  sync_fn: {SnippetSaver.Patients, :replace_patient_master_problems}

field :notes, :nested_collection,
  mode: :immediate,
  child_schema: SnippetSaver.Patients.PatientNote,
  row_fields: [:notes, :notes_important],
  create_fn: {SnippetSaver.Patients, :create_patient_note},
  update_fn: {SnippetSaver.Patients, :update_patient_note}
```

### What the generator produces vs. what stays manual

| Generated | Manual |
|---|---|
| Table/grid shell, empty state | Visual polish beyond the basic grid (future enhancement, out of scope for v1) |
| Modal open/close, edit-by-index state | — |
| Add / edit / delete event handlers | — |
| Sync call on parent save (`:buffered`) or direct call on row save (`:immediate`) | — |
| — | The row-form's actual field layout (composed from types 1-5, but the specific combination is domain-specific every time) |

---

## 6. How `mix gen.resource` works internally (recap)

1. **`Mix.Task`** (`lib/mix/tasks/gen.resource.ex`) — same mechanism as `phx.gen.live`.
2. **Spec parsing** — the `.exs` spec file is plain Elixir; `resource "..." do ... end` is a small
   set of macros (`field`, `belongs_to`, `subtab`, etc.) that accumulate into a
   `%ResourceGen.Spec{}` struct, evaluated via `Code.eval_file/1`.
3. **Template rendering** — one `.ex.eex` template per output file type (schema, context
   functions, migration, `index.ex`, `index_view.ex`, `form_component.ex`, `table.ex`, JS hook),
   each modeled directly on the existing `Patient`/`Employee` files. Rendered with
   `EEx.eval_file/2`.
4. **File writing** — `Mix.Generator.create_file/2` for new files (schema, migration); marker-
   based insertion or append for files that already have other content (context module, router).
   Router injection specifically prints a snippet for manual pasting rather than risking automatic
   corruption of `router.ex`.
5. **Output**: real files on disk. No further involvement from the spec at runtime.

---

## 7. Implementation order

1. Build the template library for field types 1, 2, 4, 3, 5 in that order (see §3) — these are the
   highest-confidence, lowest-risk wins and don't depend on anything else.
2. Build `:nested_collection` shell generation for both `:buffered` and `:immediate` modes (§5).
3. Build the quick-create (`+`) enhancement for relationship fields, one level deep only (§4).
4. Validate the whole pipeline against one real, currently-unbuilt resource as the test case
   (candidate: the Appointments module, or a first pass at Clinical Records) — generate, diff
   against what a hand-written version would look like, fix templates, repeat until output quality
   matches hand-written code closely enough to trust.
5. Only after step 4 succeeds cleanly: adopt the generator as the default starting point for all
   future modules (Clinical Records/Interventions, Users/RBAC UI, etc.).

---

## 8. Explicitly out of scope for this phase

- Two-or-more levels of nested quick-create.
- Automatic UI/UX enhancement of the nested-collection grid beyond the current table+modal shell.
- Any runtime/dynamic schema interpretation — the DSL is generation-time only.
- Retrofitting the generator onto already-built modules (Contacts, Patients, Employees stay as
  hand-written code; the generator is for new modules going forward).
- Full RBAC, `user_activity_logs`, and the Appointments/Clinical Records domain modules themselves
  — those remain tracked separately in the overall module build order.

---

## 9. Architectural decisions added on review

The following were missing from the first pass and are resolved here before implementation
starts, since getting them wrong is expensive to unwind once resources have been generated.

### 9.1 Regeneration / idempotency strategy

**Decision: init-only generation, no automatic re-diffing.** `mix gen.resource` behaves like
`phx.gen.live` — it writes files once. If a target file already exists, it prompts
`already exists, overwrite? [y/N]` per file (via `Mix.Generator`'s built-in behavior) rather than
attempting to merge changes into hand-edited code. Adding a field to an already-generated resource
later means either (a) manually editing the existing files the same way you would today, or
(b) regenerating into a scratch directory and hand-merging the diff. **No silent overwrite, ever.**
This is the safest default; smarter incremental regeneration (e.g. AST-aware field insertion) is
explicitly deferred, not attempted in v1.

Corollary: `--dry-run` flag lists every file that would be created/touched, with no writes, so you
can review the plan before committing to it. Cheap to build, meaningfully reduces risk.

### 9.2 Field-level validations

Every field declaration accepts an optional `validations:` list, applied in the generated
`changeset/2` in declaration order:

```elixir
field :email, :text, required: true, validations: [
  {:format, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email"}
]
field :weight, :number, validations: [{:number, greater_than: 0}]
```

Supported validation atoms map 1:1 to `Ecto.Changeset.validate_*` functions
(`:format`, `:length`, `:number`, `:inclusion`, `:required` via the `required:` shorthand). Custom
validations that don't fit this shape stay hand-written in the generated changeset, same as today.

### 9.3 Audit and soft-delete as resource-level options

Every `resource` block, not just nested fields, declares these explicitly:

```elixir
resource "clinical_record" do
  audit true          # adds inserted_by_id/updated_by_id + belongs_to, mirrors Settings/Patients pattern
  soft_delete false    # true = archived boolean + archive_x/2 instead of delete_x/1, mirrors Settings pattern
  ...
end
```

No default — both must be stated, same reasoning as nested-collection `mode:`: a silent default
risks the wrong data-retention behavior going unnoticed.

### 9.4 Top-level resource vs. embedded-only sub-resource

```elixir
resource "clinical_record" do
  routing :top_level        # generates routes, IndexView, subtabs, JS tab hook
  ...
end

resource "patient_note" do
  routing :embedded_only     # no routes generated; only schema + context + row-form fragment,
  ...                         # consumed via a :nested_collection field on another resource
end
```

This makes explicit what was implicit before: `PatientNote`-shaped resources get a schema and
context, but never their own `index.ex`/router entries.

### 9.5 LiveTable list/filter metadata

`list_fields` becomes a richer declaration per field rather than a flat name list:

```elixir
list_fields [
  scheduled_at: [sortable: true, filterable: true],
  patient: [sortable: false, filterable: true, computed: true],  # e.g. joined display name
  status: [sortable: true, filterable: true]
]
```

`computed: true` signals the generator to produce an `Ecto.Query.dynamic/2` fragment stub in
`table.ex` rather than a plain field reference, matching the existing pattern used for computed
full-name concatenation.

### 9.6 Test and fixture generation

Every generated resource also produces:
- `test/support/fixtures/<context>_fixtures.ex` (or appends to it, if the context already has a
  fixtures file — same append-safety caveat as §9.1 applies)
- `test/<context>/<resource>_test.exs` with the standard list/get/create/update/delete test block
  shape already used throughout the test suite

This keeps generated resources consistent with the rest of the codebase's test coverage from the
start, rather than as an afterthought.

### 9.7 Authorization hook point (for future RBAC)

Every generated context function and every generated LiveView `handle_event` gets one consistent,
currently-inert call site:

```elixir
def create_appointment(attrs, user_id \\ nil) do
  # AUTHZ_HOOK: :appointments, :create — no-op until RBAC module exists
  %Appointment{}
  |> Appointment.changeset(attrs)
  |> apply_appointment_insert_audit(user_id)
  |> Repo.insert()
end
```

Today this is a comment marker, not a real check — no RBAC module exists yet to call. When
Users/RBAC is built, a single find-and-replace-style pass across generated code can turn every
`AUTHZ_HOOK` marker into a real `Authorization.authorize!(user_id, :appointments, :create)` call,
instead of re-deriving where checks belong resource-by-resource at that point.

---

## 10. Next step

Once this document is agreed, the next artifact is the actual Claude Code spec for building the
generator itself (starting with the §3 field-type templates plus the §9 decisions above — init-only
generation with `--dry-run`, validations, audit/soft-delete toggles, routing mode, richer
list_fields, test generation, and AUTHZ_HOOK markers), followed by a first real test run against a
genuine next module.
