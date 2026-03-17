defmodule SnippetSaverWeb.EmployeeLive.Components.ShowComponent do
  use SnippetSaverWeb, :live_component

  attr :employee, :any, required: true
  attr :patch_back, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">

      <div class="flex justify-between items-start mb-6">
        <.header>
          <%= @employee.name %>
          <:subtitle><%= @employee.email %></:subtitle>
        </.header>

        <div class="flex gap-2">
          <.button
            variant="outline"
            size="sm"
            phx-click="go-to-edit"
            phx-value-id={@employee.id}
            phx-target={@myself}
          >
            <.icon name="hero-pencil" class="h-4 w-4 mr-1" />
            Edit
          </.button>
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

  def handle_event("go-to-edit", %{"id" => id}, socket) do
    send(self(), {:go_to_edit, id})
    {:noreply, socket}
  end
end
