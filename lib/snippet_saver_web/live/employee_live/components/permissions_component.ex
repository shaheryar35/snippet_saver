defmodule SnippetSaverWeb.EmployeeLive.Components.PermissionsComponent do
  use SnippetSaverWeb, :live_component

  use LiveTable.LiveResource, schema: SnippetSaver.Employees.Permission

  alias SnippetSaver.Employees
  import Ecto.Changeset

  defmodule PermissionAssignment do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :permission_id, :integer
    end

    def changeset(%__MODULE__{} = assignment, attrs, opts \\ []) do
      assignment
      |> cast(attrs, [:permission_id])
      |> maybe_validate_required(opts)
    end

    defp maybe_validate_required(changeset, opts) do
      validate_required? = Keyword.get(opts, :validate_required, true)

      if validate_required? do
        validate_required(changeset, [:permission_id])
      else
        changeset
      end
    end
  end

  attr :employee, :any, required: true
  attr :patch_back, :any, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-start mb-6">
        <.header>
          Permissions for <%= @employee.name %>
          <:subtitle><%= @employee.email %></:subtitle>
        </.header>
        <.link patch={~p"/permissions/new"}>
          <.button variant="primary" size="sm">
            <.icon name="hero-plus" class="h-4 w-4 mr-1" />
            New permission
          </.button>
        </.link>
      </div>

      <.card title="Assigned permissions">
        <%= if @assigned_permissions == [] do %>
          <.empty_state class="mt-4">
            No permissions assigned yet. Assign one below.
          </.empty_state>
        <% else %>
          <.live_table
            fields={fields()}
            filters={filters()}
            options={@table_options_runtime}
            streams={@assigned_permissions}
            per_page={[10]}
            default_per_page={10}
          />
        <% end %>
      </.card>

      <div class="mt-6">
        <.form_container title="Assign a permission">
          <.simple_form
            for={@assign_form}
            as={:assignment}
            phx-target={@myself}
            phx-submit="assign-permission"
          >
            <.input
              type="select"
              field={@assign_form[:permission_id]}
              label="Permission"
              prompt={if @available_permissions == [], do: "No permissions available", else: "Select permission"}
              options={
                Enum.map(@available_permissions, fn p ->
                  {"#{p.resource} (#{p.action})", p.id}
                end)
              }
              required
            />

            <:actions>
              <.button
                type="submit"
                variant="primary"
                size="lg"
                disabled={@available_permissions == []}
              >
                Assign
              </.button>
            </:actions>
          </.simple_form>
        </.form_container>
      </div>
    </div>
    """
  end

  def fields do
    [
      name: %{
        label: "Name",
        sortable: false,
        searchable: false,
        filter: false
      },
      resource: %{
        label: "Resource",
        sortable: false,
        searchable: false,
        filter: false
      },
      action: %{
        label: "Action",
        sortable: false,
        searchable: false,
        filter: false
      },
      description: %{
        label: "Description",
        sortable: false,
        searchable: false,
        filter: false
      },
      actions: %{
        label: "Actions",
        sortable: false,
        renderer: fn _value, permission ->
          assigns = %{permission: permission}

          ~H"""
          <div class="flex gap-2">
            <.link patch={~p"/permissions/#{@permission.id}/edit"}>
              <.button type="button" variant="outline" size="xs">
                <.icon name="hero-pencil" class="h-3 w-3" />
              </.button>
            </.link>

            <.link patch={~p"/permissions/#{@permission.id}/delete"}>
              <.button type="button" variant="danger" size="xs">
                <.icon name="hero-trash" class="h-3 w-3" />
              </.button>
            </.link>

            <.button
              type="button"
              phx-click="unassign-permission"
              phx-value-id={@permission.id}
              variant="ghost"
              size="xs"
            >
              Unassign
            </.button>
          </div>
          """
        end
      }
    ]
  end

  def filters, do: []

  def table_options do
    %{
      mode: :table,
      use_streams: false,
      pagination: %{enabled: false},
      sorting: %{enabled: false},
      search: %{enabled: false},
      exports: %{enabled: false}
    }
  end

  @impl true
  def update(%{employee: employee} = assigns, socket) do
    employee_id = employee.id

    assigned_permissions = Employees.list_permissions_for_employee(employee_id)
    available_permissions = Employees.list_available_permissions_for_employee(employee_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:assigned_permissions, assigned_permissions)
     |> assign(:available_permissions, available_permissions)
     |> assign(
       :assign_form,
       to_form(PermissionAssignment.changeset(%PermissionAssignment{}, %{}, validate_required: false))
     )
     |> assign(:table_options_runtime, %{
       "sort" => %{"sortable?" => false, "sort_params" => %{}},
       "pagination" => %{"paginate?" => false, "page" => "1", "per_page" => "10"},
       "filters" => %{"search" => ""}
     })}
  end

  @impl true
  def handle_event("assign-permission", %{"assignment" => params}, socket) do
    handle_assign_permission(params, socket)
  end

  def handle_event(
        "assign-permission",
        %{"permission_assignment" => params},
        socket
      ) do
    handle_assign_permission(params, socket)
  end

  defp handle_assign_permission(params, socket) do
    employee_id = socket.assigns.employee.id
    permission_id = Map.get(params, "permission_id")

    changeset =
      PermissionAssignment.changeset(
        %PermissionAssignment{},
        %{"permission_id" => permission_id},
        validate_required: true
      )
      |> Map.put(:action, :validate)

    if changeset.valid? do
      permission_id_int = String.to_integer(permission_id)
      Employees.assign_permission_to_employee(employee_id, permission_id_int)

      assigned_permissions = Employees.list_permissions_for_employee(employee_id)
      available_permissions = Employees.list_available_permissions_for_employee(employee_id)

      {:noreply,
       socket
       |> put_flash(:info, "Permission assigned")
       |> assign(:assigned_permissions, assigned_permissions)
       |> assign(:available_permissions, available_permissions)
       |> assign(
         :assign_form,
         to_form(PermissionAssignment.changeset(%PermissionAssignment{}, %{}, validate_required: false))
       )}
    else
      {:noreply, assign(socket, assign_form: to_form(changeset))}
    end
  end

end
