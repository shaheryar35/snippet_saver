defmodule SnippetSaverWeb.PermissionLive.Index do
  use SnippetSaverWeb, :live_view
  use LiveTable.LiveResource, schema: SnippetSaver.Employees.Permission

  alias SnippetSaver.Employees
  alias SnippetSaver.Employees.Permission

  def fields do
    [
      name: %{label: "Name", sortable: false, searchable: false, filter: false},
      resource: %{label: "Resource", sortable: false, searchable: false, filter: false},
      action: %{label: "Action", sortable: false, searchable: false, filter: false},
      description: %{label: "Description", sortable: false, searchable: false, filter: false},
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

  defp table_runtime_options do
    %{
      "sort" => %{"sortable?" => false, "sort_params" => %{}},
      "pagination" => %{"paginate?" => false, "page" => "1", "per_page" => "10"},
      "filters" => %{"search" => ""}
    }
  end

  @impl true
  def mount(params, _session, socket) do
    page =
      case socket.assigns.live_action do
        :new -> :new
        :edit -> :edit
        :delete -> :delete
        _ -> :index
      end

    socket =
      socket
      |> assign(:permission_page, page)
      |> assign(:table_options_runtime, table_runtime_options())

    {:ok, assign_permission_page(socket, page, params)}
  end

  defp assign_permission_page(socket, :index, _params) do
    permissions = Employees.list_permissions()

    socket
    |> assign(:permissions, permissions)
  end

  defp assign_permission_page(socket, :new, _params) do
    permission = %Permission{}
    changeset = Employees.change_permission(permission)

    socket
    |> assign(:permission, permission)
    |> assign(:permission_form, to_form(changeset))
  end

  defp assign_permission_page(socket, :edit, %{"id" => id}) do
    permission = Employees.get_permission!(id)
    changeset = Employees.change_permission(permission)

    socket
    |> assign(:permission, permission)
    |> assign(:permission_form, to_form(changeset))
  end

  defp assign_permission_page(socket, :delete, %{"id" => id}) do
    permission = Employees.get_permission!(id)

    socket
    |> assign(:permission, permission)
  end

  @impl true
  def handle_event("validate", %{"permission" => permission_params}, socket) do
    changeset =
      socket.assigns.permission
      |> Permission.changeset(permission_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :permission_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"permission" => permission_params}, socket) do
    case socket.assigns.permission_page do
      :new ->
        case Employees.create_permission(permission_params) do
          {:ok, %Permission{} = _permission} ->
            {:noreply,
             socket
             |> put_flash(:info, "Permission created")
             |> push_navigate(to: ~p"/permissions")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :permission_form, to_form(%{changeset | action: :validate}))}
        end

      :edit ->
        case Employees.update_permission(socket.assigns.permission, permission_params) do
          {:ok, %Permission{} = _permission} ->
            {:noreply,
             socket
             |> put_flash(:info, "Permission updated")
             |> push_navigate(to: ~p"/permissions")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :permission_form, to_form(%{changeset | action: :validate}))}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("confirm-delete", _params, socket) do
    case Employees.delete_permission(socket.assigns.permission) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "Permission deleted")
         |> push_navigate(to: ~p"/permissions")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete permission")
         |> push_navigate(to: ~p"/permissions")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <%= case @permission_page do %>
        <% :index -> %>
          <.header>
            Permissions
            <:subtitle>Define permission rules for resources/actions</:subtitle>
            <:actions>
              <.link patch={~p"/permissions/new"}>
                <.button variant="primary">New Permission</.button>
              </.link>
            </:actions>
          </.header>

          <div class="mt-4">
            <.live_table
              fields={fields()}
              filters={filters()}
              options={@table_options_runtime}
              streams={@permissions}
              per_page={[10]}
              default_per_page={10}
            />
          </div>

        <% :new -> %>
          <.header>
            New Permission
            <:subtitle>Create a new permission definition</:subtitle>
            <:actions>
              <.link patch={~p"/permissions"}>
                <.button variant="ghost">Back</.button>
              </.link>
            </:actions>
          </.header>

          <.form_container title="Permission Details">
            <.simple_form
              for={@permission_form}
              as={:permission}
              phx-change="validate"
              phx-submit="save"
            >
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  type="text"
                  field={@permission_form[:name]}
                  label="Name"
                  placeholder="e.g. employee.read"
                  required
                />
                <.input
                  type="text"
                  field={@permission_form[:resource]}
                  label="Resource"
                  placeholder="e.g. employees"
                  required
                />
                <.input
                  type="text"
                  field={@permission_form[:action]}
                  label="Action"
                  placeholder="e.g. read"
                  required
                />
                <.input
                  type="textarea"
                  field={@permission_form[:description]}
                  label="Description"
                  placeholder="Human-readable description"
                  required
                  rows={4}
                />
              </div>

              <:actions>
                <.button type="submit" variant="primary" size="lg">
                  Create Permission
                </.button>
                <.link patch={~p"/permissions"}>
                  <.button type="button" variant="outline" size="lg">
                    Cancel
                  </.button>
                </.link>
              </:actions>
            </.simple_form>
          </.form_container>

        <% :edit -> %>
          <.header>
            Edit Permission
            <:subtitle>Update permission definition</:subtitle>
            <:actions>
              <.link patch={~p"/permissions"}>
                <.button variant="ghost">Back</.button>
              </.link>
            </:actions>
          </.header>

          <.form_container title="Permission Details">
            <.simple_form
              for={@permission_form}
              as={:permission}
              phx-change="validate"
              phx-submit="save"
            >
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  type="text"
                  field={@permission_form[:name]}
                  label="Name"
                  placeholder="e.g. employee.read"
                  required
                />
                <.input
                  type="text"
                  field={@permission_form[:resource]}
                  label="Resource"
                  placeholder="e.g. employees"
                  required
                />
                <.input
                  type="text"
                  field={@permission_form[:action]}
                  label="Action"
                  placeholder="e.g. read"
                  required
                />
                <.input
                  type="textarea"
                  field={@permission_form[:description]}
                  label="Description"
                  placeholder="Human-readable description"
                  required
                  rows={4}
                />
              </div>

              <:actions>
                <.button type="submit" variant="primary" size="lg">
                  Save Changes
                </.button>
                <.link patch={~p"/permissions"}>
                  <.button type="button" variant="outline" size="lg">
                    Cancel
                  </.button>
                </.link>
              </:actions>
            </.simple_form>
          </.form_container>

        <% :delete -> %>
          <.header>
            Delete Permission
            <:subtitle>This will remove the permission definition (and unassign it from employees)</:subtitle>
            <:actions>
              <.link patch={~p"/permissions"}>
                <.button variant="ghost">Back</.button>
              </.link>
            </:actions>
          </.header>

          <.card title="Are you sure?">
            <p class="text-sm text-gray-600">
              <strong>Name:</strong> <%= @permission.name %><br />
              <strong>Resource:</strong> <%= @permission.resource %><br />
              <strong>Action:</strong> <%= @permission.action %>
            </p>

            <div class="mt-6 flex gap-3 justify-end">
              <.link patch={~p"/permissions"}>
                <.button variant="outline">Cancel</.button>
              </.link>
              <.button
                type="button"
                variant="danger"
                phx-click="confirm-delete"
              >
                Delete
              </.button>
            </div>
          </.card>
      <% end %>
    </div>
    """
  end
end

