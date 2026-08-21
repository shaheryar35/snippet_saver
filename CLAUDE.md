# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Phoenix/LiveView practice-management app (veterinary clinic — contacts, patients, employees, appointments,
tasks, and clinic settings catalogs). The `snippet_saver` app name is a holdover from project scaffolding and
does not describe the domain.

## Commands

```bash
mix setup              # deps.get + ecto.setup (create/migrate/seed) + assets.setup + assets.build
mix phx.server          # start the server (localhost:4000)
iex -S mix phx.server   # start with an IEx shell attached

mix test                          # runs ecto.create/ecto.migrate --quiet then the suite
mix test test/path/to_test.exs    # single file
mix test test/path/to_test.exs:42 # single test at line 42

mix ecto.reset          # drop, recreate, migrate, seed
mix format               # format .ex/.exs/.heex per .formatter.exs
```

DB connection env vars (`PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`) are loaded from a local
`.env` via `config/load_dotenv.exs` (see `.env-example`) for both `dev` and `test`.

## Architecture

### Contexts (`lib/snippet_saver/`)

Standard Phoenix contexts, one per domain area: `Accounts`, `Contacts`, `Patients`, `Employees`,
`Appointments`, `Settings`, `Tasks`. Each context module groups CRUD functions for its schema(s) — e.g.
`Contacts` owns `Contact`, `ContactRole`, `ContactMethod`, `Address`, `GeneralInfo`, and `ContactRoleType`
all in one file, following the generator-produced pattern (`list_x`, `get_x!`, `create_x`, `update_x`,
`delete_x`, `change_x`). When adding a new sub-resource to an existing domain, follow this pattern rather
than creating a new context.

**Settings catalogs** (`SnippetSaver.Settings`: `AppointmentType`, `AppointmentStatus`, `Species`, `Breed`,
`Colour`, `MasterProblemTemplate`) are soft-deleted, not hard-deleted: they have an `archived` boolean plus
`inserted_by_id`/`updated_by_id` audit columns (see `settings/appointment_status.ex`). "Delete" functions in
this context call `archive_x/2`, which takes a `user_id` for the audit trail. List functions typically come
in two flavors — `list_x/0` (active only, for dropdowns) and `list_x_for_admin/0` (all records, with
`inserted_by`/`updated_by` preloaded, for the settings UI).

### Web layer (`lib/snippet_saver_web/`)

- **Router** (`router.ex`): a single `live_session :app` behind `require_authenticated_user` +
  `on_mount [{UserAuth, :ensure_authenticated}]` holds virtually all app routes. Auth-flow routes
  (login/registration/reset) are separate `live_session`s with different `on_mount` hooks.
- **`*_live/index.ex`** modules are the top-level LiveView for a resource (contacts, patients, employees) and
  handle `:index` / `:new` / `:show` / `:edit` live_actions on nested routes (e.g.
  `/contacts/:id/:subtab`) within one mounted LiveView rather than separate routes per action. `render/2`
  delegates to a same-directory `IndexView.render("index.html", assigns)` module rather than an inline
  `~H` template — the actual markup lives there, keyed off assigns like `contact_page`/`active_subtab`.
- **`*_router.ex`** helper modules (e.g. `ContactLive.ContactRouter`, `EmployeeLive.EmployeeRouter`,
  `PatientLive.PatientRouter`) parse the raw URI path into a page atom and produce socket assigns for
  `handle_params` — used for sub-paths the router itself doesn't declare (e.g. `/contacts/:id/:subtab`).
  `ContactLive` is the reference implementation; `EmployeeLive` and `PatientLive` mirror it file-for-file
  (`table.ex`, `index_view.ex`, `components/`).
- Each resource's `IndexView` wires up a client-side `phx-hook` (`contact_tabs.js`, `employee_tabs.js`,
  `patient_tabs.js` in `assets/js/hooks/`) via `data-*` attributes. The hook renders a browser-tab-style bar
  of currently-open records (multiple contacts/employees/patients open at once, editor-tab style) purely in
  JS, and calls `pushEvent("navigate_to", ...)` on click — the server still owns routing and content
  rendering via `push_patch`/`handle_params`, the hook only manages which tab bar entry looks active.
- **`*_live/table.ex`** modules define `fields/0`, `filters/0`, and `table_options/0` for the `LiveTable`
  library (`use LiveTable.LiveResource, schema: ...` in the index LiveView). Field renderers are plain
  functions returning HEEx; `computed` keys use `Ecto.Query.dynamic/2` for SQL-level fragments (e.g. computed
  full-name concatenation). Table state (sort/filter/pagination) is synced through URL query params via
  `push_patch`, not just socket assigns — see `apply_table_params/3` in `ContactLive.Index`.
- **`setting_live/*_hub.ex`** are simple link-grid landing pages per settings section (`ClinicHub`,
  `PatientHub`, `ContactHub`) that `patch` into catalog-specific LiveViews (e.g.
  `SettingLive.AppointmentTypesLive`). Add new settings catalogs by wiring a new tile into the relevant hub
  plus a route in `router.ex`.
- **`components/appointment_schedule_calendar.ex`** and `appointment_live/schedule.ex` integrate the
  `calendar_component` hex package for the appointments scheduling view.
- **`DashboardLive.Index`** renders a per-module (appointment/patient/contact) swimlane board. Only the
  appointment module is backed by real data — `Appointments.appointment_swimlane_cards/0` buckets
  appointments into UPCOMING/TODAY/NEEDS RESCHEDULE/READY FOR BILLING and maps each to a plain
  `%{title, time, detail, status}` card map; patient/contact lanes are still hardcoded placeholders with
  empty card lists. Follow the same "context returns card maps keyed by lane name" shape when wiring up
  real data for the other modules.

### Auth

Standard `mix phx.gen.auth`-style setup: `Accounts` context + `Accounts.User`/`UserToken`, `UserAuth` plug/
LiveView hooks module, `UserSessionController` for login/logout. Users have a `role` field (see migration
`20260401100000_add_role_to_users.exs`).

### Background jobs

`Oban` is a dependency (`~> 2.19`) for export/background work; check `Oban.Worker` usage before assuming
long-running operations run inline in a request
.
