defmodule SnippetSaverWeb.EmployeeLive.Components.EditComponent do
  use SnippetSaverWeb, :live_component

  attr :employee, :any, required: true
  attr :patch_back, :any, required: true
  attr :parent_pid, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.link patch={@patch_back}>
        <.button variant="ghost" class="mb-4">
          <.icon name="hero-arrow-left" class="h-4 w-4 mr-1" />
          Back to Employees
        </.button>
      </.link>

      <.header>
        Edit Employee
        <:subtitle>Update team member information</:subtitle>
      </.header>

      <.live_component
        module={SnippetSaverWeb.EmployeeLive.Components.FormComponent}
        id={"edit-employee-form-#{@employee.id}"}
        title="Employee Information"
        action={:edit}
        employee={@employee}
        parent_pid={@parent_pid}
      />
    </div>
    """
  end
end
