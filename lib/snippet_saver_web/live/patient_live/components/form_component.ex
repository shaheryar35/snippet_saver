defmodule SnippetSaverWeb.PatientLive.Components.FormComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Contacts
  alias SnippetSaver.Patients
  alias SnippetSaver.Patients.Patient
  alias SnippetSaver.Settings

  @sex_options [{"Male", "male"}, {"Female", "female"}, {"Unknown", "unknown"}]
  @weight_unit_options [{"kg", "kg"}, {"lb", "lb"}]
  @resuscitate_options [{"Yes", "yes"}, {"No", "no"}, {"Discuss", "discuss"}]

  def mount(socket) do
    {:ok,
     socket
     |> assign(:sex_options, @sex_options)
     |> assign(:weight_unit_options, @weight_unit_options)
     |> assign(:resuscitate_options, @resuscitate_options)}
  end

  def update(assigns, socket) do
    selected_species_id = species_id_from_patient(assigns.patient)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:parent_pid, assigns[:parent_pid])
     |> assign_new(:master_problem_modal_mode, fn -> nil end)
     |> assign_new(:master_problem_modal_index, fn -> nil end)
     |> assign_new(:master_problem_form, fn -> nil end)
     |> assign(:selected_species_id, selected_species_id)
     |> assign_select_options()
     |> assign_master_problem_rows()
     |> assign_form()
     |> assign_new(:breed_combobox_display, fn -> "" end)
     |> assign_new(:colour_combobox_display, fn -> "" end)
     |> assign_new(:breed_combobox_open, fn -> false end)
     |> assign_new(:colour_combobox_open, fn -> false end)
     |> assign_new(:breed_combobox_suggestions, fn -> [] end)
     |> assign_new(:colour_combobox_suggestions, fn -> [] end)
     |> assign_new(:combobox_last_breed_id, fn -> :unset end)
     |> assign_new(:combobox_last_colour_id, fn -> :unset end)
     |> assign_new(:mpt_combobox_display, fn -> "" end)
     |> assign_new(:mpt_combobox_open, fn -> false end)
     |> assign_new(:mpt_combobox_suggestions, fn -> [] end)
     |> sync_breed_combobox_from_changeset()
     |> sync_colour_combobox_from_changeset()}
  end

  def handle_event("sync_form", %{"patient" => patient_params}, socket) do
    selected_species_id = patient_params["species_id"] || socket.assigns.selected_species_id

    changeset =
      socket.assigns.patient
      |> Patient.changeset(patient_params)

    socket =
      socket
      |> assign(:selected_species_id, selected_species_id)
      |> assign_select_options()

    changeset = maybe_clear_breed_if_invalid(changeset, socket.assigns.breed_catalog)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> sync_breed_combobox_from_changeset()
     |> sync_colour_combobox_from_changeset()}
  end

  def handle_event("validate", %{"patient" => patient_params}, socket) do
    changeset =
      socket.assigns.patient
      |> Patient.changeset(patient_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"patient" => patient_params}, socket) do
    save_patient(socket, socket.assigns.action, patient_params, socket.assigns.master_problem_rows)
  end

  def handle_event("open-master-problem-modal", %{"mode" => "new"}, socket) do
    {:noreply,
     socket
     |> assign(:master_problem_modal_mode, :new)
     |> assign(:master_problem_modal_index, nil)
     |> assign(:master_problem_form, to_form(blank_master_problem_row(), as: :master_problem))
     |> assign(:mpt_combobox_display, "")
     |> assign(:mpt_combobox_open, false)
     |> assign(:mpt_combobox_suggestions, [])}
  end

  def handle_event("open-master-problem-modal", %{"mode" => mode, "index" => index}, socket)
      when mode in ["view", "edit"] do
    idx = String.to_integer(index)
    row = Enum.at(socket.assigns.master_problem_rows, idx, blank_master_problem_row())
    mode_atom = String.to_existing_atom(mode)

    display =
      template_name(socket.assigns.master_problem_template_options, row["master_problem_template_id"])

    {:noreply,
     socket
     |> assign(:master_problem_modal_mode, mode_atom)
     |> assign(:master_problem_modal_index, idx)
     |> assign(:master_problem_form, to_form(row, as: :master_problem))
     |> assign(:mpt_combobox_display, display)
     |> assign(:mpt_combobox_open, false)
     |> assign(:mpt_combobox_suggestions, [])}
  end

  def handle_event("close-master-problem-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:master_problem_modal_mode, nil)
     |> assign(:master_problem_modal_index, nil)
     |> assign(:master_problem_form, nil)}
  end

  def handle_event("save-master-problem-modal", %{"master_problem" => params}, socket) do
    row = %{
      "master_problem_template_id" => Map.get(params, "master_problem_template_id", ""),
      "notes" => Map.get(params, "notes", "")
    }

    rows =
      case socket.assigns.master_problem_modal_mode do
        :edit when is_integer(socket.assigns.master_problem_modal_index) ->
          List.replace_at(socket.assigns.master_problem_rows, socket.assigns.master_problem_modal_index, row)

        _ ->
          socket.assigns.master_problem_rows ++ [row]
      end
      |> ensure_at_least_one_row()

    {:noreply,
     socket
     |> assign(:master_problem_rows, rows)
     |> assign(:master_problem_modal_mode, nil)
     |> assign(:master_problem_modal_index, nil)
     |> assign(:master_problem_form, nil)}
  end

  def handle_event("delete-master-problem-row", %{"index" => index}, socket) do
    idx = String.to_integer(index)
    rows = socket.assigns.master_problem_rows |> List.delete_at(idx) |> ensure_at_least_one_row()
    {:noreply, assign(socket, :master_problem_rows, rows)}
  end

  def handle_event("breed-combobox-focus", _params, socket) do
    q = socket.assigns.breed_combobox_display || ""
    suggestions = filter_name_tuples(socket.assigns.breed_catalog, q, 50)

    {:noreply,
     assign(socket,
       breed_combobox_open: true,
       breed_combobox_suggestions: suggestions
     )}
  end

  def handle_event("breed-combobox-search", params, socket) do
    q = Map.get(params, "breed_combobox_q", "") || ""
    suggestions = filter_name_tuples(socket.assigns.breed_catalog, q, 50)

    {:noreply,
     assign(socket,
       breed_combobox_display: q,
       breed_combobox_open: true,
       breed_combobox_suggestions: suggestions
     )}
  end

  def handle_event("breed-combobox-close", _params, socket) do
    {:noreply, assign(socket, breed_combobox_open: false)}
  end

  def handle_event("breed-combobox-pick", %{"id" => id, "label" => label}, socket) do
    breed_id = normalize_fk(id)
    cs = socket.assigns.form.source |> Ecto.Changeset.put_change(:breed_id, breed_id)

    {:noreply,
     socket
     |> assign(:form, to_form(cs))
     |> assign(:combobox_last_breed_id, breed_id)
     |> assign(:breed_combobox_display, label)
     |> assign(:breed_combobox_open, false)
     |> assign(:breed_combobox_suggestions, [])}
  end

  def handle_event("breed-combobox-clear", _params, socket) do
    cs = socket.assigns.form.source |> Ecto.Changeset.put_change(:breed_id, nil)

    {:noreply,
     socket
     |> assign(:form, to_form(cs))
     |> assign(:combobox_last_breed_id, nil)
     |> assign(:breed_combobox_display, "")
     |> assign(:breed_combobox_open, false)
     |> assign(:breed_combobox_suggestions, [])}
  end

  def handle_event("colour-combobox-focus", _params, socket) do
    q = socket.assigns.colour_combobox_display || ""
    suggestions = filter_name_tuples(socket.assigns.colour_catalog, q, 50)

    {:noreply,
     assign(socket,
       colour_combobox_open: true,
       colour_combobox_suggestions: suggestions
     )}
  end

  def handle_event("colour-combobox-search", params, socket) do
    q = Map.get(params, "colour_combobox_q", "") || ""
    suggestions = filter_name_tuples(socket.assigns.colour_catalog, q, 50)

    {:noreply,
     assign(socket,
       colour_combobox_display: q,
       colour_combobox_open: true,
       colour_combobox_suggestions: suggestions
     )}
  end

  def handle_event("colour-combobox-close", _params, socket) do
    {:noreply, assign(socket, colour_combobox_open: false)}
  end

  def handle_event("colour-combobox-pick", %{"id" => id, "label" => label}, socket) do
    colour_id = normalize_fk(id)
    cs = socket.assigns.form.source |> Ecto.Changeset.put_change(:colour_id, colour_id)

    {:noreply,
     socket
     |> assign(:form, to_form(cs))
     |> assign(:combobox_last_colour_id, colour_id)
     |> assign(:colour_combobox_display, label)
     |> assign(:colour_combobox_open, false)
     |> assign(:colour_combobox_suggestions, [])}
  end

  def handle_event("colour-combobox-clear", _params, socket) do
    cs = socket.assigns.form.source |> Ecto.Changeset.put_change(:colour_id, nil)

    {:noreply,
     socket
     |> assign(:form, to_form(cs))
     |> assign(:combobox_last_colour_id, nil)
     |> assign(:colour_combobox_display, "")
     |> assign(:colour_combobox_open, false)
     |> assign(:colour_combobox_suggestions, [])}
  end

  def handle_event("mpt-combobox-focus", _params, socket) do
    q = socket.assigns.mpt_combobox_display || ""
    suggestions = filter_name_tuples(socket.assigns.mpt_catalog, q, 50)

    {:noreply,
     assign(socket,
       mpt_combobox_open: true,
       mpt_combobox_suggestions: suggestions
     )}
  end

  def handle_event("mpt-combobox-search", params, socket) do
    q = Map.get(params, "mpt_combobox_q", "") || ""
    suggestions = filter_name_tuples(socket.assigns.mpt_catalog, q, 50)

    {:noreply,
     assign(socket,
       mpt_combobox_display: q,
       mpt_combobox_open: true,
       mpt_combobox_suggestions: suggestions
     )}
  end

  def handle_event("mpt-combobox-close", _params, socket) do
    {:noreply, assign(socket, mpt_combobox_open: false)}
  end

  def handle_event("mpt-combobox-pick", %{"id" => id, "label" => label}, socket) do
    form = socket.assigns.master_problem_form
    notes = Phoenix.HTML.Form.input_value(form, :notes) || ""

    row = %{
      "master_problem_template_id" => to_string(id),
      "notes" => to_string(notes)
    }

    {:noreply,
     socket
     |> assign(:master_problem_form, to_form(row, as: :master_problem))
     |> assign(:mpt_combobox_display, label)
     |> assign(:mpt_combobox_open, false)
     |> assign(:mpt_combobox_suggestions, [])}
  end

  def handle_event("mpt-combobox-clear", _params, socket) do
    form = socket.assigns.master_problem_form
    notes = Phoenix.HTML.Form.input_value(form, :notes) || ""

    row = %{
      "master_problem_template_id" => "",
      "notes" => to_string(notes)
    }

    {:noreply,
     socket
     |> assign(:master_problem_form, to_form(row, as: :master_problem))
     |> assign(:mpt_combobox_display, "")
     |> assign(:mpt_combobox_open, false)
     |> assign(:mpt_combobox_suggestions, [])}
  end

  defp save_patient(socket, :new, patient_params, master_problem_rows) do
    with {:ok, patient} <- Patients.create_patient(patient_params),
         {:ok, :ok} <- Patients.replace_patient_master_problems(patient.id, master_problem_rows) do
      if pid = socket.assigns[:parent_pid] do
        send(pid, {:patient_saved, patient, "Patient created successfully"})
        {:noreply, socket}
      else
        {:noreply,
         socket
         |> put_flash(:info, "Patient created successfully")
         |> push_navigate(to: ~p"/patients/#{patient}")}
      end
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:master_problem_rows, master_problem_rows)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:master_problem_rows, master_problem_rows)
         |> put_flash(:error, "Could not save master problems. Please review and try again.")}
    end
  end

  defp save_patient(socket, :edit, patient_params, master_problem_rows) do
    with {:ok, patient} <- Patients.update_patient(socket.assigns.patient, patient_params),
         {:ok, :ok} <- Patients.replace_patient_master_problems(patient.id, master_problem_rows) do
      if pid = socket.assigns[:parent_pid] do
        send(pid, {:patient_saved, patient, "Patient updated successfully"})
        {:noreply, socket}
      else
        {:noreply,
         socket
         |> put_flash(:info, "Patient updated successfully")
         |> push_navigate(to: ~p"/patients/#{patient}")}
      end
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:master_problem_rows, master_problem_rows)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:master_problem_rows, master_problem_rows)
         |> put_flash(:error, "Could not save master problems. Please review and try again.")}
    end
  end

  defp assign_form(socket) do
    changeset = Patient.changeset(socket.assigns.patient, %{})
    assign(socket, form: to_form(changeset))
  end

  defp assign_select_options(socket) do
    mpt = enum_options(Settings.list_master_problem_templates())

    assign(socket,
      contact_options: contact_options(),
      species_options: enum_options(Settings.list_species()),
      breed_catalog: breed_options_for_species(socket.assigns.selected_species_id),
      colour_catalog: enum_options(Settings.list_colours()),
      master_problem_template_options: mpt,
      mpt_catalog: mpt
    )
  end

  defp assign_master_problem_rows(socket) do
    rows =
      case socket.assigns[:patient] do
        %Patient{id: nil} ->
          [blank_master_problem_row()]

        %Patient{id: patient_id} ->
          case Patients.list_patient_master_problems_for_patient(patient_id) do
            [] ->
              [blank_master_problem_row()]

            list ->
              Enum.map(list, fn row ->
                %{
                  "master_problem_template_id" => row.master_problem_template_id && to_string(row.master_problem_template_id),
                  "notes" => row.notes || ""
                }
              end)
          end

        _ ->
          [blank_master_problem_row()]
      end

    assign(socket, :master_problem_rows, rows)
  end

  defp blank_master_problem_row do
    %{"master_problem_template_id" => "", "notes" => ""}
  end

  defp ensure_at_least_one_row([]), do: [blank_master_problem_row()]
  defp ensure_at_least_one_row(rows), do: rows

  defp template_name(options, template_id) do
    options
    |> Enum.find_value("Unknown template", fn
      {label, value} ->
        if to_string(value) == to_string(template_id), do: label, else: nil
    end)
  end

  defp contact_options do
    Contacts.list_contacts()
    |> Enum.map(fn c ->
      label =
        [c.first_name, c.last_name]
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.join(" ")
        |> case do
          "" -> "Contact ##{c.id}"
          value -> value
        end

      {label, c.id}
    end)
  rescue
    _ -> []
  end

  defp enum_options(items) do
    Enum.map(items, fn item -> {item.name, item.id} end)
  rescue
    _ -> []
  end

  defp breed_options_for_species(species_id) do
    Settings.list_breeds()
    |> Enum.filter(fn breed ->
      if species_id in [nil, ""], do: true, else: to_string(breed.species_id) == to_string(species_id)
    end)
    |> enum_options()
  rescue
    _ -> []
  end

  defp species_id_from_patient(nil), do: nil
  defp species_id_from_patient(%Patient{species_id: nil}), do: nil
  defp species_id_from_patient(%Patient{species_id: id}), do: to_string(id)

  defp sync_breed_combobox_from_changeset(socket) do
    cs = socket.assigns.form.source
    id = Ecto.Changeset.get_field(cs, :breed_id)
    last = socket.assigns.combobox_last_breed_id

    cond do
      last == :unset ->
        label = label_for_tuple_list(socket.assigns.breed_catalog, id)

        socket
        |> assign(:combobox_last_breed_id, id)
        |> assign(:breed_combobox_display, label)
        |> assign(:breed_combobox_open, false)
        |> assign(:breed_combobox_suggestions, [])

      id == last ->
        socket

      true ->
        label = label_for_tuple_list(socket.assigns.breed_catalog, id)

        socket
        |> assign(:combobox_last_breed_id, id)
        |> assign(:breed_combobox_display, label)
        |> assign(:breed_combobox_open, false)
        |> assign(:breed_combobox_suggestions, [])
    end
  end

  defp sync_colour_combobox_from_changeset(socket) do
    cs = socket.assigns.form.source
    id = Ecto.Changeset.get_field(cs, :colour_id)
    last = socket.assigns.combobox_last_colour_id

    cond do
      last == :unset ->
        label = label_for_tuple_list(socket.assigns.colour_catalog, id)

        socket
        |> assign(:combobox_last_colour_id, id)
        |> assign(:colour_combobox_display, label)
        |> assign(:colour_combobox_open, false)
        |> assign(:colour_combobox_suggestions, [])

      id == last ->
        socket

      true ->
        label = label_for_tuple_list(socket.assigns.colour_catalog, id)

        socket
        |> assign(:combobox_last_colour_id, id)
        |> assign(:colour_combobox_display, label)
        |> assign(:colour_combobox_open, false)
        |> assign(:colour_combobox_suggestions, [])
    end
  end

  defp label_for_tuple_list(_tuples, nil), do: ""

  defp label_for_tuple_list(tuples, id) do
    id_str = to_string(id)

    Enum.find_value(tuples, "", fn {label, val} ->
      if to_string(val) == id_str, do: label, else: nil
    end)
  end

  defp filter_name_tuples(tuples, query, limit) do
    q = query |> to_string() |> String.trim() |> String.downcase()

    list =
      if q == "" do
        tuples
      else
        Enum.filter(tuples, fn {label, _} ->
          String.contains?(String.downcase(label), q)
        end)
      end

    Enum.take(list, limit)
  end

  defp normalize_fk(nil), do: nil
  defp normalize_fk(""), do: nil

  defp normalize_fk(id) when is_integer(id), do: id

  defp normalize_fk(id) when is_binary(id) do
    case Integer.parse(String.trim(id)) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp maybe_clear_breed_if_invalid(changeset, breed_catalog) do
    bid = Ecto.Changeset.get_field(changeset, :breed_id)

    valid_ids =
      breed_catalog
      |> Enum.map(fn {_, v} -> v end)
      |> MapSet.new()

    if bid && !MapSet.member?(valid_ids, bid) do
      Ecto.Changeset.put_change(changeset, :breed_id, nil)
    else
      changeset
    end
  end

  def render(assigns) do
    sections = patient_sections()
    assigns = assign(assigns, :sections, sections)

    ~H"""
    <div id={"patient-form-sections-#{@id}"} phx-hook="SectionScrollSpy">
      <.form_container title={@title}>
        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
          <aside class="lg:col-span-1">
            <div class="lg:sticky lg:top-6 rounded-lg border border-gray-200 p-4 bg-gray-50">
              <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-3">Sections</p>
              <nav class="space-y-2" data-sections-nav>
                <%= for section <- @sections do %>
                  <button
                    type="button"
                    data-section-link={section.id}
                    class="w-full text-left block rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-primary-50 hover:text-primary-700 transition-colors"
                  >
                    <%= section.name %>
                  </button>
                <% end %>
              </nav>
            </div>
          </aside>

          <div class="lg:col-span-3 min-h-0">
            <div class="h-[60vh] overflow-auto pr-1" data-sections-scroll>
              <.simple_form for={@form} phx-target={@myself} phx-change="sync_form" phx-submit="save">
                <section data-section-id="basic-info" class="scroll-mt-24 mb-8">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Basic Info</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input type="text" field={@form[:patient_name]} label="Patient Name" required />
                    <.input type="text" field={@form[:code]} label="Code" />
                    <.input type="text" field={@form[:microchip_number]} label="Microchip Number" />
                    <.input type="number" field={@form[:age]} label="Age" />
                    <.input type="date" field={@form[:date_of_birth]} label="Date of Birth" />
                    <.yes_no name="patient[age_estimated]" label="Age Estimated" value={Phoenix.HTML.Form.input_value(@form, :age_estimated)} />
                    <.input type="number" field={@form[:weight]} step="0.01" label="Weight" />
                    <.input type="select" field={@form[:weight_unit]} label="Weight Unit" options={@weight_unit_options} prompt="Select unit" />
                    <.input type="select" field={@form[:sex]} label="Sex" options={@sex_options} prompt="Select sex" />
                    <.input type="select" field={@form[:resuscitate]} label="Resuscitate" options={@resuscitate_options} prompt="Select option" />
                  </div>
                </section>

                <section data-section-id="contacts" class="scroll-mt-24 mb-8">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Contacts</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input type="select" field={@form[:owner_contact_id]} label="Owner Contact" options={@contact_options} prompt="Select contact" />
                    <.input type="select" field={@form[:preferred_doctor_contact_id]} label="Preferred Doctor" options={@contact_options} prompt="Select contact" />
                    <.input type="select" field={@form[:second_preferred_doctor_contact_id]} label="Second Preferred Doctor" options={@contact_options} prompt="Select contact" />
                    <.yes_no name="patient[bill_to_other]" label="Bill To Other" value={Phoenix.HTML.Form.input_value(@form, :bill_to_other)} />
                    <.yes_no name="patient[lives_away_from_owner]" label="Lives Away From Owner" value={Phoenix.HTML.Form.input_value(@form, :lives_away_from_owner)} />
                  </div>
                </section>

                <section data-section-id="species-breed-colour" class="scroll-mt-24 mb-8">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Species / Breed / Colour</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input type="select" field={@form[:species_id]} label="Species" options={@species_options} prompt="Select species" />
                    <.searchable_select
                      field={@form[:breed_id]}
                      label="Breed"
                      placeholder="Search breeds…"
                      display={@breed_combobox_display}
                      open={@breed_combobox_open}
                      suggestions={@breed_combobox_suggestions}
                      search_name="breed_combobox_q"
                      search_event="breed-combobox-search"
                      focus_event="breed-combobox-focus"
                      close_event="breed-combobox-close"
                      pick_event="breed-combobox-pick"
                      clear_event="breed-combobox-clear"
                      phx_target={@myself}
                    />
                    <.searchable_select
                      field={@form[:colour_id]}
                      label="Colour"
                      placeholder="Search colours…"
                      display={@colour_combobox_display}
                      open={@colour_combobox_open}
                      suggestions={@colour_combobox_suggestions}
                      search_name="colour_combobox_q"
                      search_event="colour-combobox-search"
                      focus_event="colour-combobox-focus"
                      close_event="colour-combobox-close"
                      pick_event="colour-combobox-pick"
                      clear_event="colour-combobox-clear"
                      phx_target={@myself}
                    />
                    <.yes_no name="patient[is_animal_group]" label="Animal Group" value={Phoenix.HTML.Form.input_value(@form, :is_animal_group)} />
                  </div>
                </section>

                <section data-section-id="master-problems" class="scroll-mt-24 mb-8">
                  <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg font-semibold text-gray-900">Master Problems</h3>
                    <.button
                      type="button"
                      variant="primary"
                      size="sm"
                      phx-target={@myself}
                      phx-click={JS.push("open-master-problem-modal", value: %{mode: "new"}, target: @myself)}
                    >
                      + Add Master Problem
                    </.button>
                  </div>

                  <div class="overflow-x-auto border rounded-lg">
                    <table class="min-w-full text-sm">
                      <thead class="bg-gray-50 text-gray-600">
                        <tr>
                          <th class="text-left px-4 py-3 font-semibold">Master Problem</th>
                          <th class="text-left px-4 py-3 font-semibold">Notes</th>
                          <th class="text-left px-4 py-3 font-semibold">Actions</th>
                        </tr>
                      </thead>
                      <tbody class="divide-y">
                        <tr :if={Enum.empty?(Enum.filter(@master_problem_rows, fn row -> (row["master_problem_template_id"] || "") != "" end))}>
                          <td colspan="3" class="px-4 py-4 text-gray-500">No master problems added yet.</td>
                        </tr>
                        <tr
                          :for={{row, idx} <- Enum.with_index(@master_problem_rows)}
                          :if={(row["master_problem_template_id"] || "") != ""}
                        >
                          <td class="px-4 py-3">
                            <%= template_name(@master_problem_template_options, row["master_problem_template_id"]) %>
                          </td>
                          <td class="px-4 py-3"><%= row["notes"] || "—" %></td>
                          <td class="px-4 py-3">
                            <div class="flex items-center gap-2">
                              <.button
                                type="button"
                                size="sm"
                                variant="outline"
                                phx-target={@myself}
                                phx-click={JS.push("open-master-problem-modal", value: %{mode: "view", index: idx}, target: @myself)}
                              >
                                View
                              </.button>
                              <.button
                                type="button"
                                size="sm"
                                variant="outline"
                                phx-target={@myself}
                                phx-click={JS.push("open-master-problem-modal", value: %{mode: "edit", index: idx}, target: @myself)}
                              >
                                Edit
                              </.button>
                              <.button
                                type="button"
                                size="sm"
                                variant="danger"
                                phx-target={@myself}
                                phx-click="delete-master-problem-row"
                                phx-value-index={idx}
                              >
                                Delete
                              </.button>
                            </div>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>

                </section>

                <section data-section-id="insurance" class="scroll-mt-24">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Insurance</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input type="number" field={@form[:insurance_supplier_id]} label="Insurance Supplier ID" />
                    <.input type="text" field={@form[:insurance_number]} label="Insurance Number" />
                  </div>
                </section>

                <:actions>
                  <.button type="submit" variant="primary" size="lg">
                    <%= if @action == :new, do: "Create Patient", else: "Update Patient" %>
                  </.button>
                  <.link navigate={~p"/patients"}>
                    <.button type="button" variant="outline" size="lg">Cancel</.button>
                  </.link>
                </:actions>
              </.simple_form>

              <.modal
                :if={@master_problem_modal_mode}
                id={"master-problem-modal-#{@id}"}
                show
                on_cancel={JS.push("close-master-problem-modal", target: @myself)}
              >
                <%= if @master_problem_modal_mode == :view do %>
                  <div class="space-y-4">
                    <h3 class="text-lg font-semibold">Master Problem Details</h3>
                    <div class="grid grid-cols-1 gap-3 text-sm">
                      <div>
                        <p class="text-gray-500">Template</p>
                        <p class="font-medium">
                          <%= template_name(@master_problem_template_options, @master_problem_form[:master_problem_template_id].value) %>
                        </p>
                      </div>
                      <div>
                        <p class="text-gray-500">Notes</p>
                        <p class="font-medium whitespace-pre-wrap"><%= @master_problem_form[:notes].value || "—" %></p>
                      </div>
                    </div>
                    <div class="pt-2">
                      <.button type="button" variant="outline" phx-target={@myself} phx-click="close-master-problem-modal">
                        Close
                      </.button>
                    </div>
                  </div>
                <% else %>
                  <div class="space-y-4">
                    <h3 class="text-lg font-semibold">
                      <%= if @master_problem_modal_mode == :edit, do: "Edit Master Problem", else: "Add Master Problem" %>
                    </h3>
                    <.simple_form for={@master_problem_form} phx-target={@myself} phx-submit="save-master-problem-modal">
                      <div class="grid grid-cols-1 gap-4">
                        <.searchable_select
                          :if={@master_problem_form}
                          field={@master_problem_form[:master_problem_template_id]}
                          label="Template"
                          placeholder="Search templates…"
                          display={@mpt_combobox_display}
                          open={@mpt_combobox_open}
                          suggestions={@mpt_combobox_suggestions}
                          search_name="mpt_combobox_q"
                          search_event="mpt-combobox-search"
                          focus_event="mpt-combobox-focus"
                          close_event="mpt-combobox-close"
                          pick_event="mpt-combobox-pick"
                          clear_event="mpt-combobox-clear"
                          phx_target={@myself}
                        />
                        <.input type="textarea" field={@master_problem_form[:notes]} label="Notes" rows="4" />
                      </div>
                      <:actions>
                        <.button type="submit" variant="primary">
                          <%= if @master_problem_modal_mode == :edit, do: "Update", else: "Create" %>
                        </.button>
                        <.button type="button" variant="outline" phx-target={@myself} phx-click="close-master-problem-modal">
                          Cancel
                        </.button>
                      </:actions>
                    </.simple_form>
                  </div>
                <% end %>
              </.modal>
            </div>
          </div>
        </div>
      </.form_container>
    </div>
    """
  end

  defp patient_sections do
    [
      %{id: "basic-info", name: "Basic Info"},
      %{id: "contacts", name: "Contacts"},
      %{id: "species-breed-colour", name: "Species / Breed / Colour"},
      %{id: "master-problems", name: "Master Problems"},
      %{id: "insurance", name: "Insurance"}
    ]
  end
end
