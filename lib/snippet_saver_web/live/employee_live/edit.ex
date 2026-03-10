defmodule SnippetSaverWeb.EmployeeLive.Edit do
  use SnippetSaverWeb, :live_view

  alias SnippetSaver.Employees

  def mount(%{"id" => id}, _session, socket) do
    employee = Employees.get_employee!(id)

    {:ok,
     socket
     |> assign(employee: employee)
     |> assign(page_title: "Edit Employee")}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.back navigate={~p"/employees"}>Back to Employees</.back>

      <.header>
        Edit Employee
        <:subtitle>Update team member information</:subtitle>
      </.header>

      <.live_component
        module={SnippetSaverWeb.EmployeeLive.FormComponent}
        id="edit-employee-form"
        title="Employee Information"
        action={:edit}
        employee={@employee}
      />
    </div>
    """
  end
end
