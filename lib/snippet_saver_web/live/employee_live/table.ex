defmodule SnippetSaverWeb.EmployeeLive.Table do
  @moduledoc """
  LiveTable configuration for the Employee index: fields, filters, and table options.
  """
  use SnippetSaverWeb, :html
  import Ecto.Query

  def fields do
    [
      name: %{
        label: "Name",
        sortable: true,
        searchable: true,
        filter: true,
        renderer: fn name, assigns ->
          employee = assigns.actions
          assigns = %{name: name, employee: employee}

          ~H"""
          <a
            href={~p"/employees/#{@employee.id}"}
            class="employee-name-link text-left hover:text-primary-600 focus:outline-none w-full block"
            data-employee-id={@employee.id}
            data-employee-name={@employee.name}
          >
            <%= @name %>
          </a>
          """
        end
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
          id =
            if is_struct(employee), do: employee.id,
            else: employee[:id] || get_in(employee, [:actions, :id])

          assigns = %{employee: employee, id: id}

          ~H"""
          <div class="flex gap-2">
            <.button
              type="button"
              phx-click="go-to-edit"
              phx-value-id={@id}
              variant="outline"
              size="xs"
            >
              <.icon name="hero-pencil" class="h-3 w-3" />
            </.button>
            <.button
              type="button"
              phx-click="go-to-show"
              phx-value-id={@id}
              variant="outline"
              size="xs"
            >
              <.icon name="hero-eye" class="h-3 w-3" />
            </.button>
            <.button
              phx-click="delete"
              phx-value-id={@id}
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

  def filters do
    [
      active:
        LiveTable.Boolean.new(:active, "active", %{
          label: "Active Only",
          condition: dynamic([e], e.active == true)
        })
    ]
  end

  def table_options do
    %{
      use_streams: false,
      pagination: %{
        enabled: true,
        sizes: [10, 25, 50, 100],
        default_size: 10
      }
    }
  end
end
