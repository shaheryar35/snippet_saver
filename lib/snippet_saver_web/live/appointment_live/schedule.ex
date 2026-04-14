defmodule SnippetSaverWeb.AppointmentLive.Schedule do
  use SnippetSaverWeb, :live_view

  import SnippetSaverWeb.AppointmentScheduleCalendar

  alias Phoenix.LiveView.JS
  alias SnippetSaver.Appointments
  alias SnippetSaver.Appointments.{Appointment, CalendarEvent}
  alias SnippetSaver.Contacts
  alias SnippetSaver.Patients
  alias SnippetSaver.Settings

  @view_drawer_id "appointment-view-drawer"
  @new_drawer_id "appointment-new-drawer"

  # Must match <.simple_form id="…"> and be distinct per drawer — otherwise both forms
  # emit duplicate DOM ids (e.g. appointment_duration_minutes) and LiveView patching breaks.
  @appointment_edit_form_id "appointment-edit-form"
  @appointment_new_form_id "appointment-new-form"
  @default_filter_suggestion_limit 10

  @impl true
  def mount(_params, _session, socket) do
    {range_start, range_end} = default_query_range()
    selected_patient_filters = []
    selected_type_filters = []
    selected_status_filters = []
    filters = %{
      patient_ids: selected_filter_ids(selected_patient_filters),
      type_ids: selected_filter_ids(selected_type_filters),
      status_ids: selected_filter_ids(selected_status_filters)
    }
    events = load_calendar_events({range_start, range_end}, filters)
    contacts = Contacts.list_contacts_for_schedule_select()
    appointment_types = Settings.list_appointment_types()
    appointment_statuses = Settings.list_appointment_status()

    contact_options = Enum.map(contacts, &{contact_label(&1), &1.id})
    type_options = Enum.map(appointment_types, &{&1.name, &1.id})
    status_options = Enum.map(appointment_statuses, &{&1.name, &1.id})

    new_cs = new_appointment_changeset()

    {:ok,
     socket
     |> assign(:page_title, "Appointments")
     |> assign(:active_page, "appointments")
     |> assign(:current_path, "appointments")
     |> assign(:query_range, {range_start, range_end})
     |> assign(:events, events)
     |> assign(:contact_options, contact_options)
     |> assign(:type_options, type_options)
     |> assign(:status_options, status_options)
     |> assign(:patient_filter_selected, selected_patient_filters)
     |> assign(:patient_filter_query, "")
     |> assign(:patient_filter_open, false)
     |> assign(:patient_filter_suggestions, [])
     |> assign(:type_filter_selected, selected_type_filters)
     |> assign(:type_filter_query, "")
     |> assign(:type_filter_open, false)
     |> assign(:type_filter_suggestions, [])
     |> assign(:status_filter_selected, selected_status_filters)
     |> assign(:status_filter_query, "")
     |> assign(:status_filter_open, false)
     |> assign(:status_filter_suggestions, [])
     |> assign(:selected_appointment, nil)
     |> assign(:view_changeset, nil)
     |> assign(:new_changeset, new_cs)
     |> assign(:new_form, to_form(new_cs, as: :appointment, id: @appointment_new_form_id))
     |> assign(:view_form, nil)
     |> assign(:patient_combobox_display, "")
     |> assign(:patient_combobox_open, false)
     |> assign(:patient_combobox_suggestions, [])
     |> assign(:view_drawer_id, @view_drawer_id)
     |> assign(:new_drawer_id, @new_drawer_id)
     |> assign(:new_drawer_subtitle, nil)
     |> assign(:calendar_options, calendar_options())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="-mx-4 flex h-[calc(100dvh-5.5rem)] max-h-[calc(100dvh-5.5rem)] flex-col gap-3 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8 lg:h-[calc(100vh-5.5rem)] lg:max-h-[calc(100vh-5.5rem)]">
      <.header class="shrink-0">
        Appointments
      </.header>

      <div class="appointment-calendar-host flex min-h-0 flex-1 flex-col overflow-hidden rounded-lg border border-[#dadce0] bg-white shadow-sm">
        <div
          id="appointment-calendar-toolbar"
          phx-hook="AppointmentCalendarToolbar"
          phx-update="ignore"
          data-calendar-id="schedule-calendar"
          class="appointment-calendar-toolbar flex shrink-0 items-center justify-between gap-3 border-b border-[#eceff1] px-3 py-3 sm:px-4"
        >
          <div class="relative flex min-w-0 items-center gap-3">
            <button
              type="button"
              class="calendar-toolbar-date-trigger group flex min-w-0 items-center gap-3 rounded-lg px-1 py-1 text-left hover:bg-gray-50"
              data-calendar-action="pick-date"
              aria-label="Pick a date"
            >
              <div class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-1.5 text-center">
                <p
                  class="text-[10px] font-semibold uppercase tracking-wide text-gray-500"
                  data-calendar-month-short
                >
                  ---
                </p>
                <p class="text-base font-semibold leading-none text-gray-900" data-calendar-day-num>
                  --
                </p>
              </div>
              <div class="min-w-0">
                <h3 class="truncate text-base font-semibold text-gray-900" data-calendar-title>
                  Calendar
                </h3>
                <p class="truncate text-xs text-gray-500" data-calendar-range>--</p>
              </div>
            </button>
            <input
              type="date"
              class="calendar-toolbar-date-input"
              data-calendar-action="pick-date-input"
              tabindex="-1"
            />
          </div>
          <div class="flex items-center gap-2">
            <button
              type="button"
              class="calendar-toolbar-btn"
              data-calendar-action="search"
              aria-label="Search"
            >
              <.icon name="hero-magnifying-glass" class="h-4 w-4" />
            </button>
            <div class="inline-flex rounded-lg border border-gray-200 bg-white shadow-sm">
              <button
                type="button"
                class="calendar-toolbar-btn rounded-r-none border-r border-gray-200"
                data-calendar-action="prev"
                aria-label="Previous"
              >
                <.icon name="hero-chevron-left" class="h-4 w-4" />
              </button>
              <button
                type="button"
                class="calendar-toolbar-btn rounded-none border-r border-gray-200 px-3 text-xs font-medium"
                data-calendar-action="today"
              >
                Today
              </button>
              <button
                type="button"
                class="calendar-toolbar-btn rounded-l-none"
                data-calendar-action="next"
                aria-label="Next"
              >
                <.icon name="hero-chevron-right" class="h-4 w-4" />
              </button>
            </div>
            <select
              class="calendar-toolbar-select"
              data-calendar-action="view-select"
              aria-label="Calendar view"
            >
              <option value="dayGridMonth">Month view</option>
              <option value="timeGridWeek">Week view</option>
              <option value="timeGridDay">Day view</option>
              <option value="listWeek">List view</option>
            </select>
            <button
              type="button"
              class="calendar-toolbar-add-btn"
              phx-click={show_drawer(JS.push("open_new_drawer_blank"), @new_drawer_id)}
            >
              <.icon name="hero-plus" class="h-4 w-4" /> Add event
            </button>
          </div>
        </div>
        <div class="shrink-0 border-b border-[#eceff1] px-3 py-2 sm:px-4">
          <% type_filter_form =
            to_form(%{"type_filter_id" => selected_single_id(@type_filter_selected)}, as: :filters) %>
          <% status_filter_form =
            to_form(%{"status_filter_id" => selected_single_id(@status_filter_selected)}, as: :filters) %>
          <div class="mb-2 flex items-center justify-between">
            <p class="text-xs text-gray-600">
              Filters active:
              <span class="ml-1 inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-[11px] font-medium text-gray-700">
                {length(@patient_filter_selected) + length(@type_filter_selected) + length(@status_filter_selected)}
              </span>
            </p>
            <button
              :if={@patient_filter_selected != [] || @type_filter_selected != [] || @status_filter_selected != []}
              type="button"
              class="text-xs text-gray-500 hover:text-gray-800"
              phx-click="calendar-filters-clear"
            >
              Clear all
            </button>
          </div>
          <div class="grid grid-cols-1 items-start gap-2 lg:grid-cols-3">
            <div class="w-full">
            <.searchable_multi_select
              id="appointment-patient-filter"
              label="Filter by patient"
              placeholder="Search patient name or code..."
              query={@patient_filter_query}
              open={@patient_filter_open}
              selected={@patient_filter_selected}
              suggestions={@patient_filter_suggestions}
              search_name="patient_filter_q"
              search_event="patient-filter-search"
              focus_event="patient-filter-focus"
              close_event="patient-filter-close"
              pick_event="patient-filter-pick"
              remove_event="patient-filter-remove"
              clear_event="patient-filter-clear"
            />
            </div>
            <div class="w-full">
              <.searchable_select
                id="appointment-type-filter-searchable"
                field={type_filter_form[:type_filter_id]}
                label="Type"
                placeholder="Search appointment type..."
                display={selected_single_label(@type_filter_selected, @type_filter_query)}
                open={@type_filter_open}
                suggestions={@type_filter_suggestions}
                search_name="type_filter_q"
                search_event="type-filter-search"
                focus_event="type-filter-focus"
                close_event="type-filter-close"
                pick_event="type-filter-pick"
                clear_event="type-filter-clear"
                phx_target={nil}
              />
            </div>
            <div class="w-full">
              <.searchable_select
                id="appointment-status-filter-searchable"
                field={status_filter_form[:status_filter_id]}
                label="Status"
                placeholder="Search status..."
                display={selected_single_label(@status_filter_selected, @status_filter_query)}
                open={@status_filter_open}
                suggestions={@status_filter_suggestions}
                search_name="status_filter_q"
                search_event="status-filter-search"
                focus_event="status-filter-focus"
                close_event="status-filter-close"
                pick_event="status-filter-pick"
                clear_event="status-filter-clear"
                phx_target={nil}
              />
            </div>
          </div>
        </div>
        <.appointment_schedule_calendar
          id="schedule-calendar"
          events={@events}
          options={@calendar_options}
          on_event_click={JS.push("event_clicked")}
          on_date_click={JS.push("date_clicked")}
          on_month_change={JS.push("month_changed")}
          class="h-full min-h-0 w-full flex-1"
        />
      </div>

      <.drawer
        id={@view_drawer_id}
        on_cancel={hide_drawer(@view_drawer_id) |> JS.push("closed_view_drawer")}
      >
        <h3 id={"#{@view_drawer_id}-title"} class="text-lg font-semibold text-gray-900">
          Edit appointment
        </h3>
        <p id={"#{@view_drawer_id}-description"} class="text-sm text-gray-600">
          Update the visit details below.
        </p>

        <div :if={@selected_appointment} class="mt-6 space-y-6">
          <div class="rounded-lg border border-gray-100 bg-gray-50 p-4 text-sm text-gray-700 space-y-2">
            <p :if={@selected_appointment.patient}>
              <span class="font-medium text-gray-900">Patient:</span>
              {@selected_appointment.patient.patient_name}
              <.link
                navigate={~p"/patients/#{@selected_appointment.patient_id}"}
                class="ml-2 text-primary-600 hover:underline"
              >
                Open record
              </.link>
            </p>
            <p :if={@selected_appointment.appointment_type}>
              <span class="font-medium text-gray-900">Type:</span> {@selected_appointment.appointment_type.name}
            </p>
            <p :if={@selected_appointment.appointment_status}>
              <span class="font-medium text-gray-900">Status:</span> {@selected_appointment.appointment_status.name}
            </p>
            <p :if={@selected_appointment.doctor_contact}>
              <span class="font-medium text-gray-900">Doctor:</span> {contact_label(
                @selected_appointment.doctor_contact
              )}
            </p>
            <p :if={@selected_appointment.owner_contact}>
              <span class="font-medium text-gray-900">Owner:</span> {contact_label(
                @selected_appointment.owner_contact
              )}
            </p>
            <p><span class="font-medium text-gray-900">Room:</span> {@selected_appointment.room}</p>
          </div>

          <.simple_form
            :if={@view_form}
            for={@view_form}
            id="appointment-edit-form"
            phx-submit="update_appointment"
          >
            <.input
              field={@view_form[:appointment_datetime]}
              type="datetime-local"
              label="Start (UTC)"
              required
            />
            <.input
              field={@view_form[:duration_minutes]}
              type="number"
              label="Duration (minutes)"
              required
            />
            <.input field={@view_form[:reason]} type="text" label="Reason" required />
            <.input field={@view_form[:room]} type="text" label="Room" required />
            <input
              type="hidden"
              name={@view_form[:patient_id].name}
              value={patient_id_value(@view_form)}
            />
            <.input
              field={@view_form[:appointment_type_id]}
              type="select"
              label="Type"
              prompt="None"
              options={@type_options}
            />
            <.input
              field={@view_form[:appointment_status_id]}
              type="select"
              label="Status"
              prompt="None"
              options={@status_options}
            />
            <.input
              field={@view_form[:doctor_contact_id]}
              type="select"
              label="Doctor"
              prompt="None"
              options={@contact_options}
            />
            <.input
              field={@view_form[:owner_contact_id]}
              type="select"
              label="Owner contact"
              prompt="None"
              options={@contact_options}
            />
            <:actions>
              <.button type="submit" variant="primary">Save changes</.button>
              <.button
                type="button"
                variant="outline"
                phx-click={hide_drawer(@view_drawer_id) |> JS.push("closed_view_drawer")}
              >
                Cancel
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </.drawer>

      <.drawer
        id={@new_drawer_id}
        on_cancel={hide_drawer(@new_drawer_id) |> JS.push("closed_new_drawer")}
      >
        <h3 id={"#{@new_drawer_id}-title"} class="text-lg font-semibold text-gray-900">
          New appointment
        </h3>
        <p id={"#{@new_drawer_id}-description"} class="text-sm text-gray-600">
          {if(@new_drawer_subtitle,
            do: @new_drawer_subtitle,
            else:
              "Add a visit to the calendar. Click a day or time on the calendar to pre-fill the start time."
          )}
        </p>

        <div class="mt-6">
          <.simple_form for={@new_form} id="appointment-new-form" phx-submit="create_appointment">
            <.input
              field={@new_form[:appointment_datetime]}
              type="datetime-local"
              label="Start (UTC)"
              required
            />
            <.input
              field={@new_form[:duration_minutes]}
              type="number"
              label="Duration (minutes)"
              required
            />
            <.input field={@new_form[:reason]} type="text" label="Reason" required />
            <.input field={@new_form[:room]} type="text" label="Room" required />

            <label class="block text-sm font-medium text-gray-700 mb-1">Patient</label>
            <input
              type="hidden"
              name={@new_form[:patient_id].name}
              id="new-patient-hidden"
              value={patient_id_value(@new_form)}
            />
            <div class="relative mb-4">
              <div class="relative flex gap-1">
                <input
                  type="text"
                  id="new-patient-query"
                  name="patient_combobox_q"
                  value={@patient_combobox_display}
                  placeholder="Search patient name or code…"
                  autocomplete="off"
                  phx-change="patient-combobox-search"
                  phx-debounce="200"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
                <button
                  :if={patient_id_value(@new_form) != ""}
                  type="button"
                  class="shrink-0 rounded-lg border border-gray-300 px-2 py-2 text-xs text-gray-600 hover:bg-gray-50"
                  phx-click="patient-combobox-clear"
                  aria-label="Clear patient"
                >
                  <.icon name="hero-x-mark" class="h-4 w-4" />
                </button>
              </div>
              <div
                :if={@patient_combobox_open && @patient_combobox_suggestions != []}
                class="absolute z-20 mt-1 max-h-60 w-full overflow-auto rounded-lg border border-gray-200 bg-white py-1 shadow-lg"
                role="listbox"
              >
                <button
                  :for={p <- @patient_combobox_suggestions}
                  type="button"
                  role="option"
                  class="block w-full px-3 py-2 text-left text-sm text-gray-900 hover:bg-primary-50"
                  phx-click="patient-combobox-pick"
                  phx-value-id={p.id}
                  phx-value-label={patient_suggestion_label(p)}
                >
                  {patient_suggestion_label(p)}
                </button>
              </div>
            </div>

            <.input
              field={@new_form[:appointment_type_id]}
              type="select"
              label="Type"
              prompt="None"
              options={@type_options}
            />
            <.input
              field={@new_form[:appointment_status_id]}
              type="select"
              label="Status"
              prompt="None"
              options={@status_options}
            />
            <.input
              field={@new_form[:doctor_contact_id]}
              type="select"
              label="Doctor"
              prompt="None"
              options={@contact_options}
            />
            <.input
              field={@new_form[:owner_contact_id]}
              type="select"
              label="Owner contact"
              prompt="None"
              options={@contact_options}
            />
            <:actions>
              <.button type="submit" variant="primary">Create</.button>
              <.button
                type="button"
                variant="outline"
                phx-click={hide_drawer(@new_drawer_id) |> JS.push("closed_new_drawer")}
              >
                Cancel
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </.drawer>
    </div>
    """
  end

  defp patient_id_value(form) do
    v = form[:patient_id].value
    if v in [nil, ""], do: "", else: to_string(v)
  end

  defp patient_suggestion_label(p) do
    code = if p.code in [nil, ""], do: "", else: " (#{p.code})"
    "#{p.patient_name}#{code}"
  end

  @impl true
  def handle_event("event_clicked", params, socket) do
    raw_id = Map.get(params, "id") || get_in(params, ["event", "id"])
    id = parse_id(raw_id)

    if is_nil(id) do
      {:noreply, put_flash(socket, :error, "Invalid appointment.")}
    else
      apt = Appointments.get_appointment_for_calendar!(id)
      cs = Appointments.change_appointment(apt, %{})

      {:noreply,
       socket
       |> assign(:selected_appointment, apt)
       |> assign(:view_changeset, cs)
       |> assign(:view_form, to_form(cs, as: :appointment, id: @appointment_edit_form_id))
       |> push_event("appointment_show_view_drawer", %{js: encode_show_view_drawer_js()})}
    end
  end

  @impl true
  def handle_event("date_clicked", %{"date" => iso} = params, socket) when is_binary(iso) do
    dt = parse_clicked_datetime(iso)
    duration = duration_from_selection(dt, Map.get(params, "end") || Map.get(params, :end))

    cs =
      %Appointment{}
      |> Appointments.change_appointment(%{})
      |> Ecto.Changeset.put_change(:appointment_datetime, dt)
      |> Ecto.Changeset.put_change(:duration_minutes, duration)

    subtitle = new_drawer_subtitle_for_slot(dt, duration)

    {:noreply,
     socket
     |> assign(:new_changeset, cs)
     |> assign(:new_form, to_form(cs, as: :appointment, id: @appointment_new_form_id))
     |> assign(:new_drawer_subtitle, subtitle)
     |> assign(:patient_combobox_display, "")
     |> assign(:patient_combobox_open, false)
     |> assign(:patient_combobox_suggestions, [])
     |> push_event("appointment_show_new_drawer", %{js: encode_show_new_drawer_js()})}
  end

  def handle_event("date_clicked", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("open_new_drawer_blank", _, socket) do
    new_cs = new_appointment_changeset()

    {:noreply,
     socket
     |> assign(:new_changeset, new_cs)
     |> assign(:new_form, to_form(new_cs, as: :appointment, id: @appointment_new_form_id))
     |> assign(:new_drawer_subtitle, nil)
     |> assign(:patient_combobox_display, "")
     |> assign(:patient_combobox_open, false)
     |> assign(:patient_combobox_suggestions, [])}
  end

  @impl true
  def handle_event("month_changed", params, socket) do
    start_iso = Map.get(params, "start") || ""

    {range_start, range_end} =
      if start_iso != "" do
        expand_range_from_calendar_start(start_iso)
      else
        default_query_range()
      end

    events = load_calendar_events({range_start, range_end}, current_filter_ids(socket.assigns))

    {:noreply,
     socket
     |> assign(:query_range, {range_start, range_end})
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("closed_view_drawer", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_appointment, nil)
     |> assign(:view_changeset, nil)
     |> assign(:view_form, nil)}
  end

  @impl true
  def handle_event("closed_new_drawer", _, socket) do
    new_cs = new_appointment_changeset()

    {:noreply,
     socket
     |> assign(:new_changeset, new_cs)
     |> assign(:new_form, to_form(new_cs, as: :appointment, id: @appointment_new_form_id))
     |> assign(:new_drawer_subtitle, nil)
     |> assign(:patient_combobox_display, "")
     |> assign(:patient_combobox_open, false)
     |> assign(:patient_combobox_suggestions, [])}
  end

  @impl true
  def handle_event("patient-combobox-search", %{"patient_combobox_q" => q}, socket) do
    q = q || ""
    suggestions = Patients.search_patients(q)
    open = String.trim(q) != ""

    {:noreply,
     socket
     |> assign(:patient_combobox_display, q)
     |> assign(:patient_combobox_open, open)
     |> assign(:patient_combobox_suggestions, suggestions)}
  end

  def handle_event("patient-combobox-search", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("patient-combobox-pick", %{"id" => id, "label" => label}, socket) do
    id = parse_id(id)
    cs = Ecto.Changeset.put_change(socket.assigns.new_changeset, :patient_id, id)

    {:noreply,
     socket
     |> assign(:new_changeset, cs)
     |> assign(:new_form, to_form(cs, as: :appointment, id: @appointment_new_form_id))
     |> assign(:patient_combobox_display, label)
     |> assign(:patient_combobox_open, false)
     |> assign(:patient_combobox_suggestions, [])}
  end

  @impl true
  def handle_event("patient-combobox-clear", _, socket) do
    cs = Ecto.Changeset.put_change(socket.assigns.new_changeset, :patient_id, nil)

    {:noreply,
     socket
     |> assign(:new_changeset, cs)
     |> assign(:new_form, to_form(cs, as: :appointment, id: @appointment_new_form_id))
     |> assign(:patient_combobox_display, "")
     |> assign(:patient_combobox_open, false)
     |> assign(:patient_combobox_suggestions, [])}
  end

  @impl true
  def handle_event("patient-filter-focus", _params, socket) do
    selected_ids = selected_filter_ids(socket.assigns.patient_filter_selected) |> MapSet.new()

    suggestions =
      Patients.search_patients("")
      |> Enum.reject(fn p -> MapSet.member?(selected_ids, p.id) end)
      |> Enum.map(fn p -> {patient_suggestion_label(p), p.id} end)
      |> Enum.take(@default_filter_suggestion_limit)

    {:noreply,
     socket
     |> assign(:patient_filter_open, true)
     |> assign(:patient_filter_suggestions, suggestions)}
  end

  @impl true
  def handle_event("patient-filter-close", _params, socket) do
    {:noreply, assign(socket, :patient_filter_open, false)}
  end

  @impl true
  def handle_event("patient-filter-search", params, socket) when is_map(params) do
    q =
      Map.get(params, "patient_filter_q") ||
        Map.get(params, "value") ||
        ""

    selected_ids = selected_filter_ids(socket.assigns.patient_filter_selected) |> MapSet.new()

    suggestions =
      Patients.search_patients(q)
      |> Enum.reject(fn p -> MapSet.member?(selected_ids, p.id) end)
      |> Enum.map(fn p -> {patient_suggestion_label(p), p.id} end)
      |> Enum.take(@default_filter_suggestion_limit)

    {:noreply,
     socket
     |> assign(:patient_filter_query, q)
     |> assign(:patient_filter_open, String.trim(q) != "")
     |> assign(:patient_filter_suggestions, suggestions)}
  end

  def handle_event("patient-filter-search", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("patient-filter-pick", %{"id" => id, "label" => label}, socket) do
    pid = parse_id(id)

    selected =
      socket.assigns.patient_filter_selected
      |> Enum.reject(fn {_label, existing_id} -> existing_id == pid end)
      |> then(fn list -> list ++ [{label, pid}] end)

    filters = current_filter_ids(socket.assigns, %{patient_ids: selected_filter_ids(selected)})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply,
     socket
     |> assign(:patient_filter_selected, selected)
     |> assign(:patient_filter_open, false)
     |> assign(:patient_filter_suggestions, [])
     |> assign(:patient_filter_query, "")
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("patient-filter-remove", %{"id" => id}, socket) do
    pid = parse_id(id)

    selected =
      Enum.reject(socket.assigns.patient_filter_selected, fn {_label, sid} -> sid == pid end)

    filters = current_filter_ids(socket.assigns, %{patient_ids: selected_filter_ids(selected)})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply,
     socket
     |> assign(:patient_filter_selected, selected)
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("patient-filter-clear", _params, socket) do
    {rs, re} = socket.assigns.query_range
    filters = current_filter_ids(socket.assigns, %{patient_ids: []})
    events = load_calendar_events({rs, re}, filters)

    {:noreply,
     socket
     |> assign(:patient_filter_selected, [])
     |> assign(:patient_filter_query, "")
     |> assign(:patient_filter_open, false)
     |> assign(:patient_filter_suggestions, [])
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("type-filter-focus", _params, socket) do
    selected_ids = selected_filter_ids(socket.assigns.type_filter_selected)
    suggestions = filter_tuple_suggestions("", socket.assigns.type_options, selected_ids)

    {:noreply,
     socket
     |> assign(:type_filter_open, true)
     |> assign(:type_filter_suggestions, suggestions)}
  end

  @impl true
  def handle_event("type-filter-close", _params, socket) do
    {:noreply, assign(socket, :type_filter_open, false)}
  end

  @impl true
  def handle_event("type-filter-search", params, socket) when is_map(params) do
    q = Map.get(params, "type_filter_q") || Map.get(params, "value") || ""
    selected_ids = selected_filter_ids(socket.assigns.type_filter_selected)
    suggestions = filter_tuple_suggestions(q, socket.assigns.type_options, selected_ids)

    {:noreply,
     socket
     |> assign(:type_filter_query, q)
     |> assign(:type_filter_open, true)
     |> assign(:type_filter_suggestions, suggestions)}
  end

  def handle_event("type-filter-search", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("type-filter-pick", %{"id" => id, "label" => label}, socket) do
    tid = parse_id(id)
    selected = if is_integer(tid), do: [{label, tid}], else: []

    filters = current_filter_ids(socket.assigns, %{type_ids: selected_filter_ids(selected)})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply,
     socket
     |> assign(:type_filter_selected, selected)
     |> assign(:type_filter_open, false)
     |> assign(:type_filter_query, "")
     |> assign(:type_filter_suggestions, [])
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("type-filter-remove", %{"id" => id}, socket) do
    tid = parse_id(id)
    selected = Enum.reject(socket.assigns.type_filter_selected, fn {_l, sid} -> sid == tid end)
    filters = current_filter_ids(socket.assigns, %{type_ids: selected_filter_ids(selected)})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply, socket |> assign(:type_filter_selected, selected) |> assign(:events, events)}
  end

  @impl true
  def handle_event("type-filter-clear", _params, socket) do
    filters = current_filter_ids(socket.assigns, %{type_ids: []})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply,
     socket
     |> assign(:type_filter_selected, [])
     |> assign(:type_filter_query, "")
     |> assign(:type_filter_open, false)
     |> assign(:type_filter_suggestions, [])
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("status-filter-focus", _params, socket) do
    selected_ids = selected_filter_ids(socket.assigns.status_filter_selected)
    suggestions = filter_tuple_suggestions("", socket.assigns.status_options, selected_ids)

    {:noreply,
     socket
     |> assign(:status_filter_open, true)
     |> assign(:status_filter_suggestions, suggestions)}
  end

  @impl true
  def handle_event("status-filter-close", _params, socket) do
    {:noreply, assign(socket, :status_filter_open, false)}
  end

  @impl true
  def handle_event("status-filter-search", params, socket) when is_map(params) do
    q = Map.get(params, "status_filter_q") || Map.get(params, "value") || ""
    selected_ids = selected_filter_ids(socket.assigns.status_filter_selected)
    suggestions = filter_tuple_suggestions(q, socket.assigns.status_options, selected_ids)

    {:noreply,
     socket
     |> assign(:status_filter_query, q)
     |> assign(:status_filter_open, true)
     |> assign(:status_filter_suggestions, suggestions)}
  end

  def handle_event("status-filter-search", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("status-filter-pick", %{"id" => id, "label" => label}, socket) do
    sid = parse_id(id)
    selected = if is_integer(sid), do: [{label, sid}], else: []

    filters = current_filter_ids(socket.assigns, %{status_ids: selected_filter_ids(selected)})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply,
     socket
     |> assign(:status_filter_selected, selected)
     |> assign(:status_filter_open, false)
     |> assign(:status_filter_query, "")
     |> assign(:status_filter_suggestions, [])
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("status-filter-remove", %{"id" => id}, socket) do
    sid = parse_id(id)
    selected = Enum.reject(socket.assigns.status_filter_selected, fn {_l, existing_id} -> existing_id == sid end)
    filters = current_filter_ids(socket.assigns, %{status_ids: selected_filter_ids(selected)})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply, socket |> assign(:status_filter_selected, selected) |> assign(:events, events)}
  end

  @impl true
  def handle_event("status-filter-clear", _params, socket) do
    filters = current_filter_ids(socket.assigns, %{status_ids: []})
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, filters)

    {:noreply,
     socket
     |> assign(:status_filter_selected, [])
     |> assign(:status_filter_query, "")
     |> assign(:status_filter_open, false)
     |> assign(:status_filter_suggestions, [])
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("calendar-filters-clear", _params, socket) do
    {rs, re} = socket.assigns.query_range
    events = load_calendar_events({rs, re}, %{patient_ids: [], type_ids: [], status_ids: []})

    {:noreply,
     socket
     |> assign(:patient_filter_selected, [])
     |> assign(:patient_filter_query, "")
     |> assign(:patient_filter_open, false)
     |> assign(:patient_filter_suggestions, [])
     |> assign(:type_filter_selected, [])
     |> assign(:type_filter_query, "")
     |> assign(:type_filter_open, false)
     |> assign(:type_filter_suggestions, [])
     |> assign(:status_filter_selected, [])
     |> assign(:status_filter_query, "")
     |> assign(:status_filter_open, false)
     |> assign(:status_filter_suggestions, [])
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("create_appointment", params, socket) do
    case params do
      %{"appointment" => ap_params} ->
        user = socket.assigns.current_user

        attrs =
          ap_params
          |> normalize_optional_ids()
          |> normalize_datetime_param()
          |> Map.put("created_by", user.id)
          |> Map.put("updated_by", user.id)

        case Appointments.create_appointment(attrs) do
          {:ok, _} ->
            {rs, re} = socket.assigns.query_range
            events = load_calendar_events({rs, re}, current_filter_ids(socket.assigns))
            new_cs = new_appointment_changeset()

            {:noreply,
             socket
             |> put_flash(:info, "Appointment created.")
             |> assign(:events, events)
             |> assign(:new_changeset, new_cs)
             |> assign(:new_form, to_form(new_cs, as: :appointment, id: @appointment_new_form_id))
             |> assign(:new_drawer_subtitle, nil)
             |> assign(:patient_combobox_display, "")
             |> assign(:patient_combobox_open, false)
             |> assign(:patient_combobox_suggestions, [])
             |> push_event("appointment_hide_new_drawer", %{js: encode_hide_new_drawer_js()})}

          {:error, %Ecto.Changeset{} = cs} ->
            {:noreply,
             socket
             |> assign(:new_changeset, cs)
             |> assign(:new_form, to_form(cs, as: :appointment, id: @appointment_new_form_id))
             |> put_flash(:error, "Please fix the errors below.")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid form submission.")}
    end
  end

  @impl true
  def handle_event("update_appointment", %{"appointment" => params}, socket) do
    user = socket.assigns.current_user
    apt = socket.assigns.selected_appointment

    if is_nil(apt) do
      {:noreply, put_flash(socket, :error, "No appointment selected.")}
    else
      attrs =
        params
        |> normalize_optional_ids()
        |> normalize_datetime_param()
        |> Map.put("updated_by", user.id)

      case Appointments.update_appointment(apt, attrs) do
        {:ok, _} ->
          {rs, re} = socket.assigns.query_range
          events = load_calendar_events({rs, re}, current_filter_ids(socket.assigns))

          {:noreply,
           socket
           |> put_flash(:info, "Appointment updated.")
           |> assign(:events, events)
           |> assign(:selected_appointment, nil)
           |> assign(:view_changeset, nil)
           |> assign(:view_form, nil)
           |> push_event("appointment_hide_view_drawer", %{js: encode_hide_view_drawer_js()})}

        {:error, %Ecto.Changeset{} = cs} ->
          {:noreply,
           socket
           |> assign(:view_changeset, cs)
           |> assign(:view_form, to_form(cs, as: :appointment, id: @appointment_edit_form_id))
           |> put_flash(:error, "Please fix the errors below.")}
      end
    end
  end

  defp encode_show_new_drawer_js do
    js = %JS{} |> show_drawer(@new_drawer_id)
    # Same payload as phx-click={…} but without HTML escaping — execJS expects raw JSON.
    Phoenix.json_library().encode!(js.ops)
  end

  defp encode_show_view_drawer_js do
    js = %JS{} |> show_drawer(@view_drawer_id)
    Phoenix.json_library().encode!(js.ops)
  end

  defp encode_hide_new_drawer_js do
    js = %JS{} |> hide_drawer(@new_drawer_id)
    Phoenix.json_library().encode!(js.ops)
  end

  defp encode_hide_view_drawer_js do
    js = %JS{} |> hide_drawer(@view_drawer_id)
    Phoenix.json_library().encode!(js.ops)
  end

  defp new_appointment_changeset do
    %Appointment{}
    |> Appointments.change_appointment(%{})
    |> Ecto.Changeset.put_change(:appointment_datetime, default_slot_start())
    |> Ecto.Changeset.put_change(:duration_minutes, 30)
  end

  defp calendar_options do
    %{
      # EventCalendar applies `view` on init; `initialView` is still used by LiveCalendar for plugins.
      view: "dayGridMonth",
      initialView: "dayGridMonth",
      firstDay: 1,
      headerToolbar: %{
        start: "title",
        end: "today prev,next dayGridMonth,timeGridWeek,timeGridDay,listWeek"
      },
      titleFormat: %{year: "numeric", month: "long"},
      buttonText: %{
        today: "Today",
        month: "Month",
        week: "Week",
        day: "Day",
        list: "List"
      },
      dayHeaderFormat: %{weekday: "short"},
      dayMaxEvents: true,
      selectable: true,
      selectMirror: true,
      unselectAuto: true,
      nowIndicator: true,
      height: "100%",
      # timeGridWeek / timeGridDay: visible hour range (not month view).
      # Use 00:00–24:00 for a full day; narrow these if you only want clinic hours.
      slotMinTime: "00:00:00",
      slotMaxTime: "24:00:00",
      scrollTime: "08:00:00",
      allDaySlot: true,
      weekends: true,
      displayEventEnd: true,
      # Read by AppointmentScheduleCalendar hook (push-only event / date handlers).
      lv: %{onDateClick: "date_clicked", onEventClick: "event_clicked"}
    }
  end

  defp default_query_range do
    today = Date.utc_today()
    start_at = DateTime.new!(Date.add(today, -7), ~T[00:00:00.000000], "Etc/UTC")
    end_at = DateTime.new!(Date.add(today, 45), ~T[23:59:59.999999], "Etc/UTC")
    {start_at, end_at}
  end

  defp default_slot_start do
    DateTime.utc_now() |> DateTime.add(1, :day) |> DateTime.truncate(:second)
  end

  defp expand_range_from_calendar_start(start_iso) do
    date =
      case Date.from_iso8601(String.slice(start_iso, 0, 10)) do
        {:ok, d} -> d
        _ -> Date.utc_today()
      end

    start_at = DateTime.new!(Date.add(date, -7), ~T[00:00:00.000000], "Etc/UTC")
    end_at = DateTime.new!(Date.add(date, 55), ~T[23:59:59.999999], "Etc/UTC")
    {start_at, end_at}
  end

  defp parse_clicked_datetime(iso) when is_binary(iso) do
    iso = String.trim(iso)

    cond do
      match?({:ok, _, _}, DateTime.from_iso8601(iso)) ->
        {:ok, dt, _} = DateTime.from_iso8601(iso)
        DateTime.truncate(dt, :second)

      match?({:ok, _}, NaiveDateTime.from_iso8601(iso)) ->
        iso
        |> NaiveDateTime.from_iso8601!()
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.truncate(:second)

      true ->
        case Date.from_iso8601(String.slice(iso, 0, 10)) do
          {:ok, d} -> DateTime.new!(d, ~T[09:00:00], "Etc/UTC")
          _ -> DateTime.utc_now() |> DateTime.truncate(:second)
        end
    end
  end

  defp duration_from_selection(start_dt, end_iso) when is_binary(end_iso) and end_iso != "" do
    end_dt = parse_clicked_datetime(end_iso)
    secs = DateTime.diff(end_dt, start_dt, :second)

    cond do
      secs <= 0 ->
        30

      true ->
        mins = div(secs, 60)
        min(24 * 60, max(15, mins))
    end
  end

  defp duration_from_selection(_, _), do: 30

  defp selected_filter_ids(selected) when is_list(selected) do
    selected
    |> Enum.map(fn {_label, id} -> id end)
    |> Enum.filter(&is_integer/1)
  end

  defp selected_single_id([{_label, id} | _]) when is_integer(id), do: id
  defp selected_single_id(_), do: nil

  defp selected_single_label([{label, _id} | _], _query), do: label
  defp selected_single_label([], query), do: query

  defp current_filter_ids(assigns, overrides \\ %{}) do
    %{
      patient_ids: selected_filter_ids(assigns.patient_filter_selected),
      type_ids: selected_filter_ids(assigns.type_filter_selected),
      status_ids: selected_filter_ids(assigns.status_filter_selected)
    }
    |> Map.merge(overrides)
  end

  defp filter_tuple_suggestions(query, options, selected_ids) do
    selected = MapSet.new(selected_ids)
    q = String.trim(to_string(query || "")) |> String.downcase()

    options
    |> Enum.reject(fn {_label, id} -> MapSet.member?(selected, id) end)
    |> Enum.filter(fn {label, _id} ->
      q == "" || String.contains?(String.downcase(to_string(label)), q)
    end)
    |> Enum.take(@default_filter_suggestion_limit)
  end

  defp load_calendar_events({%DateTime{} = start_at, %DateTime{} = end_at}, filters) do
    Appointments.list_appointments_between(start_at, end_at)
    |> filter_appointments(filters)
    |> CalendarEvent.from_appointments()
  end

  defp filter_appointments(appointments, %{patient_ids: pids, type_ids: tids, status_ids: sids}) do
    appointments
    |> filter_by_patient_ids(pids)
    |> filter_by_type_ids(tids)
    |> filter_by_status_ids(sids)
  end

  defp filter_by_patient_ids(appointments, []), do: appointments

  defp filter_by_patient_ids(appointments, patient_ids) do
    ids = MapSet.new(patient_ids)

    Enum.filter(appointments, fn a ->
      not is_nil(a.patient_id) and MapSet.member?(ids, a.patient_id)
    end)
  end

  defp filter_by_type_ids(appointments, []), do: appointments

  defp filter_by_type_ids(appointments, type_ids) do
    ids = MapSet.new(type_ids)

    Enum.filter(appointments, fn a ->
      not is_nil(a.appointment_type_id) and MapSet.member?(ids, a.appointment_type_id)
    end)
  end

  defp filter_by_status_ids(appointments, []), do: appointments

  defp filter_by_status_ids(appointments, status_ids) do
    ids = MapSet.new(status_ids)

    Enum.filter(appointments, fn a ->
      not is_nil(a.appointment_status_id) and MapSet.member?(ids, a.appointment_status_id)
    end)
  end

  defp new_drawer_subtitle_for_slot(%DateTime{} = start, duration) do
    "Starts #{format_utc_datetime_line(start)} · #{duration} min (edit below if needed)."
  end

  defp format_utc_datetime_line(%DateTime{} = dt) do
    {:ok, date} = Date.new(dt.year, dt.month, dt.day)
    dow = Date.day_of_week(date)
    dow_s = Enum.at(~w(Mon Tue Wed Thu Fri Sat Sun), dow - 1)
    mon_s = Enum.at(~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec), dt.month - 1)
    hh = String.pad_leading(to_string(dt.hour), 2, "0")
    mm = String.pad_leading(to_string(dt.minute), 2, "0")
    "#{dow_s} #{mon_s} #{dt.day}, #{dt.year} — #{hh}:#{mm} UTC"
  end

  defp parse_id(nil), do: nil
  defp parse_id(id) when is_integer(id), do: id

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp contact_label(%SnippetSaver.Contacts.Contact{} = c) do
    [c.first_name, c.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> "Contact ##{c.id}"
      s -> s
    end
  end

  defp normalize_optional_ids(params) when is_map(params) do
    Enum.reduce(
      ~w(patient_id owner_contact_id doctor_contact_id appointment_type_id appointment_status_id),
      params,
      fn k, acc ->
        v = Map.get(acc, k, "")

        if v in [nil, "", []] do
          Map.put(acc, k, nil)
        else
          acc
        end
      end
    )
  end

  defp normalize_datetime_param(params) when is_map(params) do
    case Map.get(params, "appointment_datetime") do
      bin when is_binary(bin) ->
        case datetime_local_to_utc(bin) do
          {:ok, dt} -> Map.put(params, "appointment_datetime", dt)
          :error -> params
        end

      _ ->
        params
    end
  end

  defp datetime_local_to_utc(s) when is_binary(s) do
    s = String.trim(s)

    naive =
      cond do
        String.match?(s, ~r/T\d{2}:\d{2}$/) ->
          NaiveDateTime.from_iso8601!(s <> ":00")

        match?({:ok, _}, NaiveDateTime.from_iso8601(s)) ->
          elem(NaiveDateTime.from_iso8601(s), 1)

        true ->
          nil
      end

    if naive do
      {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
    else
      :error
    end
  end
end
