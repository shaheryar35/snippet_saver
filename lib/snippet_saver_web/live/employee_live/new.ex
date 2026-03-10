defmodule SnippetSaverWeb.EmployeeLive.New do
  use SnippetSaverWeb, :live_view

  alias SnippetSaver.Employees
  alias SnippetSaver.Employees.Employee

  def mount(_params, _session, socket) do
    employee = %Employee{}

    {:ok,
     socket
     |> assign(employee: employee)
     |> assign(page_title: "New Employee")}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.back navigate={~p"/employees"}>Back to Employees</.back>

      <.header>
        New Employee
        <:subtitle>Add a new team member</:subtitle>
      </.header>

      <.live_component
        module={SnippetSaverWeb.EmployeeLive.FormComponent}
        id="new-employee-form"
        title="Employee Information"
        action={:new}
        employee={@employee}
      />
    </div>
    """
  end
end
