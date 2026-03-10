defmodule SnippetSaverWeb.EmployeeLive.Index do
  use SnippetSaverWeb, :live_view
  use LiveTable.LiveResource, schema: SnippetSaver.Employees.Employee

  alias SnippetSaver.Employees

  # LiveTable field definitions
  def fields do
    [
      name: %{
        label: "Name",
        sortable: true,
        searchable: true,
        filter: true
      },
      email: %{
        label: "Email",
        sortable: true,
        searchable: true
      },
      company: %{
        label: "Company",
        sortable: true,
        searchable: true
      },
      department: %{
        label: "Department",
        sortable: true,
        filter: true,
        renderer: fn department ->
          department || "—"
        end
      },
      role: %{
        label: "Role",
        sortable: true,
        filter: true,
        renderer: fn role ->
          role || "—"
        end
      },
      active: %{
        label: "Status",
        sortable: true,
        renderer: fn active ->
          assigns = %{active: active}
          ~H"""
          <%= if @active do %>
            <.badge variant="success">Active</.badge>
          <% else %>
            <.badge variant="danger">Inactive</.badge>
          <% end %>
          """
        end
      },
      salary: %{
        label: "Salary",
        sortable: true,
        renderer: fn salary ->
          if salary do
            "$#{Decimal.to_string(salary, :normal)}"
          else
            "—"
          end
        end
      },
      actions: %{
        label: "Actions",
        sortable: false,
        computed: dynamic([resource: r], r),
        renderer: fn employee ->
          assigns = %{employee: employee}

          ~H"""
          <div class="flex gap-2">
            <.link navigate={~p"/employees/#{@employee.id}/edit"}>
              <.button variant="outline" size="xs">
                <.icon name="hero-pencil" class="h-3 w-3" />
              </.button>
            </.link>
            <.button
              phx-click="delete"
              phx-value-id={@employee.id}
              variant="danger"
              size="xs"
              data-confirm="Are you sure?"
            >
              <.icon name="hero-trash" class="h-3 w-3" />
            </.button>
          </div>
          """
        end
      }
    ]
  end

  # LiveTable table options - required for pagination default_size
  def table_options do
    %{
      pagination: %{
        enabled: true,
        sizes: [10, 25, 50, 100],
        default_size: 10
      }
    }
  end

  # LiveTable filter definitions - must use structs (Boolean.new, Range.new)
  def filters do
    [
      active: LiveTable.Boolean.new(:active, "active", %{
        label: "Active Only",
        condition: dynamic([e], e.active == true)
      }),
      salary_range: LiveTable.Range.new(:salary, "salary_range", %{
        type: :number,
        label: "Salary Range",
        min: 0,
        max: 200_000,
        step: 5000
      })
    ]
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Employees"
     )}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    employee = Employees.get_employee!(id)

    case Employees.delete_employee(employee) do
      {:ok, _employee} ->
        {:noreply,
         socket
         |> put_flash(:info, "Employee deleted")
         |> push_patch(to: ~p"/employees")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete employee")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        Employees
        <:subtitle>Manage your team members</:subtitle>
        <:actions>
          <.link navigate={~p"/employees/new"}>
            <.button variant="primary">Add Employee</.button>
          </.link>
        </:actions>
      </.header>

      <!-- LiveTable Employee List -->
      <div class="mt-6">
        <.live_table
          fields={fields()}
          filters={filters()}
          options={@options}
          streams={@streams}
          per_page={[10, 25, 50, 100]}
          default_per_page={10}
          show_search={true}
          show_columns_toggle={true}
          show_export={true}
        />
      </div>
    </div>
    """
  end
end
