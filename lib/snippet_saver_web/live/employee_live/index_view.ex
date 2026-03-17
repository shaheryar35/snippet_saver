defmodule SnippetSaverWeb.EmployeeLive.IndexView do
  @moduledoc """
  View and templates for the Employee LiveView. Unified layout: HEADER, TABS (client-rendered), PAGE CONTENT.
  Tab UI state is managed by the EmployeeTabs JS hook; server only loads data and sends open_employee_tab events.
  """
  use SnippetSaverWeb, :html

  def render("index.html", assigns) do
    show_employee? = assigns[:employee_page] in [:show, :edit] and is_map_key(assigns, :employee)
    is_new_page? = assigns[:employee_page] == :new

    active_subtab =
      case Map.get(assigns, :active_subtab) do
        nil -> :details
        val -> val
      end

    assigns =
      assigns
      |> assign(:show_employee?, show_employee?)
      |> assign(:data_employee_id, if(show_employee?, do: assigns.employee.id, else: nil))
      |> assign(:data_employee_name, if(show_employee?, do: assigns.employee.name, else: nil))
      |> assign(:data_page_new, is_new_page?)
      |> assign(:active_subtab, active_subtab)

    ~H"""
    <div
      id="employee-tab-system"
      class="container mx-auto px-4 py-8"
      phx-hook="EmployeeTabs"
      data-employee-id={@data_employee_id}
      data-employee-name={@data_employee_name}
      data-page-new={@data_page_new}
      data-employee-subtab={if @employee_page == :show, do: @active_subtab, else: nil}
    >
      <.header>
        Employees
        <:subtitle>Manage your team members</:subtitle>
        <:actions>
          <.link patch={~p"/employees/new"} class="add-employee-link">
            <.button variant="primary">Add Employee</.button>
          </.link>
        </:actions>
      </.header>

      <div id="employee-tabs" phx-update="ignore"></div>

      <div id="employee-content" class="content border border-t-0 border-gray-200 bg-white rounded-b-lg shadow-sm min-h-[320px]">
        <%= case @employee_page do %>
          <% :index -> %>
            <div class="p-4">
              <%= @table_content.(assigns) %>
            </div>

          <% :show -> %>
            <div class="p-4">
              <%= case @active_subtab do %>
                <% :activity -> %>
                  <.live_component
                    module={SnippetSaverWeb.EmployeeLive.Components.ActivityComponent}
                    id={"employee-activity-#{@employee.id}"}
                    employee={@employee}
                    patch_back={~p"/employees"}
                  />

                <% :permissions -> %>
                  <.live_component
                    module={SnippetSaverWeb.EmployeeLive.Components.PermissionsComponent}
                    id={"employee-permissions-#{@employee.id}"}
                    employee={@employee}
                    patch_back={~p"/employees"}
                  />

                <% _ -> %>
                  <.live_component
                    module={SnippetSaverWeb.EmployeeLive.Components.ShowComponent}
                    id={"employee-show-#{@employee.id}"}
                    employee={@employee}
                    patch_back={~p"/employees"}
                  />
              <% end %>
            </div>

          <% :edit -> %>
            <div class="p-4">
              <.live_component
                module={SnippetSaverWeb.EmployeeLive.Components.EditComponent}
                id={"employee-edit-#{@employee.id}"}
                employee={@employee}
                patch_back={~p"/employees"}
                parent_pid={@parent_pid}
              />
            </div>

          <% :new -> %>
            <div class="p-4">
              <.live_component
                module={SnippetSaverWeb.EmployeeLive.Components.NewComponent}
                id="employee-new"
                employee={@employee}
                patch_back={~p"/employees"}
                parent_pid={@parent_pid}
              />
            </div>

          <% _ -> %>
            <div class="p-4">
              <%= @table_content.(assigns) %>
            </div>
        <% end %>
      </div>
    </div>
    """
  end
end
