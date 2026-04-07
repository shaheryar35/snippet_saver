defmodule SnippetSaverWeb.PatientLive.Index do
  use SnippetSaverWeb, :live_view
  use LiveTable.LiveResource, schema: SnippetSaver.Patients.Patient

  alias SnippetSaver.Patients
  alias SnippetSaver.Patients.Patient
  alias SnippetSaverWeb.PatientLive.IndexView
  alias SnippetSaverWeb.PatientLive.Table

  def fields, do: Table.fields()
  def filters, do: Table.filters()
  def table_options, do: Table.table_options()

  @impl true
  def mount(params, _session, socket) do
    socket = assign_patient_page_from_live_action(socket, params)
    {:ok, socket}
  end

  defp assign_patient_page_from_live_action(socket, params) do
    id = Map.get(params || %{}, "id")

    case socket.assigns[:live_action] do
      :new ->
        socket
        |> assign(:patient_page, :new)
        |> assign(:patient, %Patient{})
        |> assign(:page_title, "New Patient")
        |> assign(:active_page, "patients")

      :show when is_binary(id) and id != "" ->
        patient = Patients.get_patient!(id)

        socket
        |> assign(:patient_page, :show)
        |> assign(:patient, patient)
        |> assign(:page_title, patient.patient_name || "Patient ##{patient.id}")
        |> assign(:active_page, "patients")

      :edit when is_binary(id) and id != "" ->
        patient = Patients.get_patient!(id)

        socket
        |> assign(:patient_page, :edit)
        |> assign(:patient, patient)
        |> assign(:page_title, "Edit Patient")
        |> assign(:active_page, "patients")

      _ ->
        assign(socket, :patient_page, :index)
    end
  end

  @impl true
  def handle_params(params, uri, socket) do
    path_segments =
      uri |> URI.parse() |> Map.get(:path, "") |> String.trim_leading("/") |> String.split("/")

    cond do
      path_segments == ["patients"] ->
        apply_table_params(socket, params, path_segments)

      path_segments == ["patients", "new"] ->
        socket =
          socket
          |> assign(:patient_page, :new)
          |> assign(:patient, %Patient{})
          |> assign(:page_title, "New Patient")
          |> assign(:active_page, "patients")
          |> push_event("open_patient_tab", %{patient: %{id: "new", name: "New Patient"}})

        {:noreply, socket}

      match?(["patients", _id], path_segments) and not match?(["patients", "new"], path_segments) ->
        patient = Patients.get_patient!(params["id"])

        socket =
          socket
          |> assign(:patient_page, :show)
          |> assign(:patient, patient)
          |> assign(:active_subtab, :details)
          |> assign(:page_title, patient_display_name(patient))
          |> assign(:active_page, "patients")
          |> push_event("open_patient_tab", %{patient: %{id: patient.id, name: patient_display_name(patient)}})

        {:noreply, socket}

      match?(["patients", _id, "edit"], path_segments) ->
        patient = Patients.get_patient!(params["id"])

        socket =
          socket
          |> assign(:patient_page, :edit)
          |> assign(:patient, patient)
          |> assign(:active_subtab, :details)
          |> assign(:page_title, "Edit Patient")
          |> assign(:active_page, "patients")
          |> push_event("open_patient_tab", %{patient: %{id: patient.id, name: patient_display_name(patient)}})

        {:noreply, socket}

      true ->
        apply_table_params(socket, params, path_segments)
    end
  end

  defp apply_table_params(socket, params, path_segments) do
    current_path = Enum.join(path_segments, "/")
    opts = get_merged_table_options()
    default_sort = get_in(opts, [:sorting, :default_sort]) || [id: :asc]

    sort_params =
      (params["sort_params"] || default_sort)
      |> Enum.map(fn
        {k, v} when is_atom(k) and is_atom(v) -> {k, v}
        {k, v} -> {String.to_existing_atom(k), String.to_existing_atom(v)}
      end)

    filters =
      (params["filters"] || %{})
      |> Map.put("search", params["search"] || "")
      |> Enum.reduce(%{}, fn
        {"search", search_term}, acc -> Map.put(acc, "search", search_term)
        {k, _}, acc -> Map.put(acc, String.to_existing_atom(k), get_filter(k))
      end)

    options = %{
      "sort" => %{
        "sortable?" => get_in(opts, [:sorting, :enabled]),
        "sort_params" => sort_params
      },
      "pagination" => %{
        "paginate?" => get_in(opts, [:pagination, :enabled]),
        "page" => params["page"] || "1",
        "per_page" => params["per_page"] || to_string(get_in(opts, [:pagination, :default_size]) || 10)
      },
      "filters" => filters
    }

    {resources, updated_options} =
      case stream_resources(fields(), options, SnippetSaver.Patients.Patient) do
        {resources, overflow} ->
          options = put_in(options["pagination"][:has_next_page], length(overflow) > 0)
          {resources, options}

        resources when is_list(resources) ->
          {resources, options}
      end

    socket =
      socket
      |> assign(:resources, resources)
      |> assign(:options, updated_options)
      |> assign(:current_path, current_path)
      |> assign(:patient_page, :index)
      |> assign(:page_title, "Patients")
      |> assign(:active_page, "patients")

    {:noreply, socket}
  end

  def handle_event("go-to-edit", %{"id" => id}, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:patient_page, :edit)
     |> assign(:patient, patient)
     |> assign(:active_subtab, :details)
     |> assign(:page_title, "Edit Patient")
     |> assign(:active_page, "patients")
     |> push_patch(to: ~p"/patients/#{id}/edit")}
  end

  def handle_event("go-to-show", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/patients/#{id}")}
  end

  def handle_event("open-patient-tab", %{"id" => id}, socket) do
    patient = Patients.get_patient!(id)
    socket = push_event(socket, "open_patient_tab", %{patient: %{id: patient.id, name: patient_display_name(patient)}})
    {:noreply, socket}
  end

  def handle_event("navigate_to", %{"patient_id" => patient_id, "subtab" => _subtab}, socket) do
    patient = Patients.get_patient!(patient_id)

    {:noreply,
     socket
     |> assign(:patient_page, :show)
     |> assign(:patient, patient)
     |> assign(:active_subtab, :details)
     |> assign(:page_title, patient_display_name(patient))
     |> assign(:active_page, "patients")
     |> push_patch(to: ~p"/patients/#{patient_id}")}
  end

  def handle_event("navigate_to", %{"patient_id" => patient_id}, socket) do
    handle_event("navigate_to", %{"patient_id" => patient_id, "subtab" => "details"}, socket)
  end

  def handle_event("navigate_to", %{"id" => id}, socket) do
    case id do
      "list" ->
        list_params = %{
          "page" => "1",
          "per_page" => "10",
          "sort_params" => %{"id" => "asc"},
          "filters" => %{},
          "search" => ""
        }

        {:noreply, socket} = apply_table_params(socket, list_params, ["patients"])
        {:noreply, push_patch(socket, to: ~p"/patients?page=1&per_page=10&sort_params[id]=asc")}

      "new" ->
        {:noreply,
         socket
         |> assign(:patient_page, :new)
         |> assign(:patient, %Patient{})
         |> assign(:page_title, "New Patient")
         |> assign(:active_page, "patients")
         |> push_patch(to: ~p"/patients/new")}

      _ ->
        patient = Patients.get_patient!(id)

        {:noreply,
         socket
         |> assign(:patient_page, :show)
         |> assign(:patient, patient)
         |> assign(:active_subtab, :details)
         |> assign(:page_title, patient_display_name(patient))
         |> assign(:active_page, "patients")
         |> push_patch(to: ~p"/patients/#{id}")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    patient = Patients.get_patient!(id)

    case Patients.delete_patient(patient) do
      {:ok, _deleted} ->
        {:noreply, socket |> put_flash(:info, "Patient deleted") |> push_patch(to: ~p"/patients")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete patient")}
    end
  end

  @impl true
  def handle_info({:go_to_edit, id}, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:patient_page, :edit)
     |> assign(:patient, patient)
     |> assign(:active_subtab, :details)
     |> assign(:page_title, "Edit Patient")
     |> assign(:active_page, "patients")
     |> push_patch(to: ~p"/patients/#{id}/edit")}
  end

  @impl true
  def handle_info({:patient_saved, patient, message}, socket) do
    {:noreply,
     socket
     |> assign(:patient_page, :show)
     |> assign(:patient, patient)
     |> assign(:active_subtab, :details)
     |> assign(:page_title, patient_display_name(patient))
     |> assign(:active_page, "patients")
     |> put_flash(:info, message)
     |> push_patch(to: ~p"/patients/#{patient}")}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:table_content, &__MODULE__.render_table/1)
      |> maybe_assign_parent_pid()

    IndexView.render("index.html", assigns)
  end

  defp maybe_assign_parent_pid(assigns) do
    case Map.get(assigns, :patient_page) do
      :new -> assign(assigns, :parent_pid, self())
      :edit -> assign(assigns, :parent_pid, self())
      _ -> assigns
    end
  end

  def render_table(assigns) do
    ~H"""
    <.live_table
      fields={fields()}
      filters={filters()}
      options={Map.get(assigns, :options, %{})}
      streams={Map.get(assigns, :streams, Map.get(assigns, :resources, []))}
      per_page={[10, 25, 50, 100]}
      default_per_page={10}
      show_search={true}
      show_columns_toggle={true}
      show_export={true}
    />
    """
  end

  defp patient_display_name(patient) do
    case String.trim(patient.patient_name || "") do
      "" -> "Patient ##{patient.id}"
      name -> name
    end
  end
end
