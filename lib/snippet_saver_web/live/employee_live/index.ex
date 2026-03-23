defmodule SnippetSaverWeb.EmployeeLive.Index do
  use SnippetSaverWeb, :live_view
  use LiveTable.LiveResource, schema: SnippetSaver.Employees.Employee

  alias SnippetSaver.Employees
  alias SnippetSaver.Employees.Employee
  alias SnippetSaverWeb.EmployeeLive.Table
  alias SnippetSaverWeb.EmployeeLive.EmployeeRouter
  alias SnippetSaverWeb.EmployeeLive.IndexView

  # Delegate LiveTable config to Table module
  def fields, do: Table.fields()
  def filters, do: Table.filters()
  def table_options, do: Table.table_options()

  @impl true
  def mount(params, _session, socket) do
    socket = assign_employee_page_from_live_action(socket, params)
    {:ok, socket}
  end

  defp assign_employee_page_from_live_action(socket, params) do
    id = Map.get(params || %{}, "id")

    case socket.assigns[:live_action] do
      :new ->
        socket
        |> assign(:employee_page, :new)
        |> assign(:employee, %Employee{})
        |> assign(:page_title, "New Employee")
        |> assign(:active_page, "employees")

      :show when is_binary(id) and id != "" ->
        employee = Employees.get_employee!(id)
        socket
        |> assign(:employee_page, :show)
        |> assign(:employee, employee)
        |> assign(:page_title, employee.name)
        |> assign(:active_page, "employees")

      :edit when is_binary(id) and id != "" ->
        employee = Employees.get_employee!(id)
        socket
        |> assign(:employee_page, :edit)
        |> assign(:employee, employee)
        |> assign(:page_title, "Edit Employee")
        |> assign(:active_page, "employees")

      _ ->
        assign(socket, :employee_page, :index)
    end
  end

  @impl true
  def handle_params(params, uri, socket) do
    path_segments = uri |> URI.parse() |> Map.get(:path, "") |> String.trim_leading("/") |> String.split("/")

    cond do
      path_segments == ["employees"] ->
        apply_table_params(socket, params, path_segments)

      # Explicitly handle edit path so form shows when patching to /employees/:id/edit
      match?(["employees", _, "edit"], path_segments) ->
        id = Enum.at(path_segments, 1)
        employee = Employees.get_employee!(id)
        socket =
          socket
          |> assign(:employee_page, :edit)
          |> assign(:employee, employee)
          |> assign(:page_title, "Edit Employee")
          |> assign(:active_page, "employees")
        {:noreply, socket}

      true ->
        case EmployeeRouter.handle(params, uri, socket) do
          {:index, socket, params, path} ->
            apply_table_params(socket, params, path)

          {:noreply, socket} ->
            socket =
              case socket.assigns[:employee_page] do
                :new ->
                  push_event(socket, "open_employee_tab", %{
                    employee: %{id: "new", name: "New Employee"}
                  })
                :show when is_map_key(socket.assigns, :employee) ->
                  emp = socket.assigns.employee
                  push_event(socket, "open_employee_tab", %{
                    employee: %{id: emp.id, name: emp.name}
                  })
                :edit when is_map_key(socket.assigns, :employee) ->
                  emp = socket.assigns.employee
                  push_event(socket, "open_employee_tab", %{
                    employee: %{id: emp.id, name: emp.name}
                  })
                _ ->
                  socket
              end
            {:noreply, socket}
        end
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
      case stream_resources(fields(), options, SnippetSaver.Employees.Employee) do
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
      |> assign(:employee_page, :index)
      |> assign(:page_title, "Employees")
      |> assign(:active_page, "employees")

    {:noreply, socket}
  end

  def handle_event("open-employee-tab", %{"id" => id}, socket) do
    employee = Employees.get_employee!(id)
    # Only push event; client adds tab then sends navigate_to so server can reply with employee content
    socket =
      push_event(socket, "open_employee_tab", %{
        employee: %{id: employee.id, name: employee.name}
      })
    {:noreply, socket}
  end

  # Nested tab navigation: employee + subtab (details/activity/permissions)
  def handle_event("navigate_to", %{"employee_id" => employee_id, "subtab" => subtab}, socket) do
    employee = Employees.get_employee!(employee_id)

    active_subtab =
      case subtab do
        "details" -> :details
        "activity" -> :activity
        "permissions" -> :permissions
        _ -> :details
      end

    socket =
      socket
      |> assign(:employee_page, :show)
      |> assign(:employee, employee)
      |> assign(:active_subtab, active_subtab)
      |> assign(:page_title, employee.name)
      |> assign(:active_page, "employees")
      |> push_patch(to: ~p"/employees/#{employee_id}/#{subtab}")

    {:noreply, socket}
  end

  # Backwards-compatible navigation using only an id (list/new/show)
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

        {:noreply, socket} = apply_table_params(socket, list_params, ["employees"])
        socket = push_patch(socket, to: ~p"/employees?page=1&per_page=10&sort_params[id]=asc")
        {:noreply, socket}

      "new" ->
        socket =
          socket
          |> assign(:employee_page, :new)
          |> assign(:employee, %Employee{})
          |> assign(:page_title, "New Employee")
          |> assign(:active_page, "employees")
          |> push_patch(to: ~p"/employees/new")

        {:noreply, socket}

      _ ->
        employee = Employees.get_employee!(id)

        socket =
          socket
          |> assign(:employee_page, :show)
          |> assign(:employee, employee)
          |> assign(:active_subtab, :details)
          |> assign(:page_title, employee.name)
          |> assign(:active_page, "employees")
          |> push_patch(to: ~p"/employees/#{id}")

        {:noreply, socket}
    end
  end

  def handle_event("go-to-edit", %{"id" => id}, socket) do
    # Assign edit page in this reply so the form shows immediately (same as navigate_to for show)
    employee = Employees.get_employee!(id)
    socket =
      socket
      |> assign(:employee_page, :edit)
      |> assign(:employee, employee)
      |> assign(:page_title, "Edit Employee")
      |> assign(:active_page, "employees")
      |> push_patch(to: ~p"/employees/#{id}/edit")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:go_to_edit, id}, socket) do
    # Edit link inside ShowComponent sends this so we assign + patch and the form shows
    employee = Employees.get_employee!(id)
    socket =
      socket
      |> assign(:employee_page, :edit)
      |> assign(:employee, employee)
      |> assign(:page_title, "Edit Employee")
      |> assign(:active_page, "employees")
      |> push_patch(to: ~p"/employees/#{id}/edit")
    {:noreply, socket}
  end

  def handle_event("go-to-show", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/employees/#{id}")}
  end

  def handle_event("nav-employees", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/employees?page=1&per_page=10&sort_params[id]=asc")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    employee = Employees.get_employee!(id)

    case Employees.delete_employee(employee) do
      {:ok, _employee} ->
        socket =
          socket
          |> put_flash(:info, "Employee deleted")
          |> push_patch(to: ~p"/employees")

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete employee")}
    end
  end

  def handle_event("unassign-permission", %{"id" => permission_id}, socket) do
    employee_id = socket.assigns.employee.id
    permission_id_int = String.to_integer(permission_id)

    _count = Employees.unassign_permission_from_employee(employee_id, permission_id_int)

    {:noreply,
     socket
     |> put_flash(:info, "Permission unassigned")
     |> push_patch(to: ~p"/employees/#{employee_id}/permissions")}
  end

  @impl true
  def handle_info({:employee_saved, employee, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_patch(to: ~p"/employees/#{employee}")}
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
    case Map.get(assigns, :employee_page) do
      :new -> assign(assigns, :parent_pid, self())
      :edit -> assign(assigns, :parent_pid, self())
      _ -> assigns
    end
  end

  @doc "Renders the LiveTable fragment for the index page (called from IndexView)."
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
end
