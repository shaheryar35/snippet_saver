defmodule SnippetSaverWeb.EmployeeLive.Show do
  use SnippetSaverWeb, :live_view

  alias SnippetSaver.Employees

  def mount(%{"id" => id}, _session, socket) do
    employee = Employees.get_employee!(id)

    {:ok,
     socket
     |> assign(employee: employee)
     |> assign(page_title: employee.name)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.back navigate={~p"/employees"}>Back to Employees</.back>

      <div class="flex justify-between items-start mb-6">
        <.header>
          <%= @employee.name %>
          <:subtitle><%= @employee.email %></:subtitle>
        </.header>

        <div class="flex gap-2">
          <.link patch={~p"/employees/#{@employee.id}/edit"}>
            <.button variant="outline" size="sm">
              <.icon name="hero-pencil" class="h-4 w-4 mr-1" />
              Edit
            </.button>
          </.link>
        </div>
      </div>

      <.card>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <p class="text-sm text-gray-500">Company</p>
            <p class="font-medium"><%= @employee.company %></p>
          </div>
          <div>
            <p class="text-sm text-gray-500">Department</p>
            <p class="font-medium"><%= @employee.department || "—" %></p>
          </div>
          <div>
            <p class="text-sm text-gray-500">Role</p>
            <p class="font-medium"><%= @employee.role || "—" %></p>
          </div>
          <div>
            <p class="text-sm text-gray-500">Status</p>
            <.badge variant={if @employee.active, do: "success", else: "danger"}>
              <%= if @employee.active, do: "Active", else: "Inactive" %>
            </.badge>
          </div>
          <div>
            <p class="text-sm text-gray-500">Salary</p>
            <p class="font-medium">
              <%= if @employee.salary do %>
                $<%= Decimal.to_string(@employee.salary, :normal) %>
              <% else %>
                —
              <% end %>
            </p>
          </div>
        </div>
      </.card>
    </div>
    """
  end
end
