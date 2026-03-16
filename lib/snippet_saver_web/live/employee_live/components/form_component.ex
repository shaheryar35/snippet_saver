defmodule SnippetSaverWeb.EmployeeLive.Components.FormComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Employees
  alias SnippetSaver.Employees.Employee

  @departments [
    {"Engineering", "engineering"},
    {"Sales", "sales"},
    {"Marketing", "marketing"},
    {"HR", "hr"},
    {"Finance", "finance"},
    {"Operations", "operations"}
  ]

  @roles [
    {"Junior", "junior"},
    {"Mid-Level", "mid"},
    {"Senior", "senior"},
    {"Lead", "lead"},
    {"Manager", "manager"},
    {"Director", "director"}
  ]

  def mount(socket) do
    {:ok, assign(socket, departments: @departments, roles: @roles)}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:parent_pid, assigns[:parent_pid])
     |> assign_form()}
  end

  def handle_event("validate", %{"employee" => employee_params}, socket) do
    changeset =
      socket.assigns.employee
      |> Employee.changeset(employee_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"employee" => employee_params}, socket) do
    save_employee(socket, socket.assigns.action, employee_params)
  end

  defp save_employee(socket, :new, employee_params) do
    case Employees.create_employee(employee_params) do
      {:ok, employee} ->
        if pid = socket.assigns[:parent_pid] do
          send(pid, {:employee_saved, employee, "Employee created successfully"})
          {:noreply, socket}
        else
          {:noreply,
           socket
           |> put_flash(:info, "Employee created successfully")
           |> push_navigate(to: ~p"/employees/#{employee}")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_employee(socket, :edit, employee_params) do
    case Employees.update_employee(socket.assigns.employee, employee_params) do
      {:ok, employee} ->
        if pid = socket.assigns[:parent_pid] do
          send(pid, {:employee_saved, employee, "Employee updated successfully"})
          {:noreply, socket}
        else
          {:noreply,
           socket
           |> put_flash(:info, "Employee updated successfully")
           |> push_navigate(to: ~p"/employees/#{employee}")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp assign_form(socket) do
    changeset = Employee.changeset(socket.assigns.employee, %{})
    assign(socket, form: to_form(changeset))
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form_container title={@title}>
        <.simple_form
          for={@form}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              type="text"
              field={@form[:name]}
              label="Full Name"
              placeholder="John Doe"
              required
            />

            <.input
              type="email"
              field={@form[:email]}
              label="Email Address"
              placeholder="john@company.com"
              required
            />

            <.input
              type="text"
              field={@form[:company]}
              label="Company"
              placeholder="Acme Inc."
              required
            />

            <.input
              type="select"
              field={@form[:department]}
              label="Department"
              prompt="Select department"
              options={@departments}
            />

            <.input
              type="select"
              field={@form[:role]}
              label="Role"
              prompt="Select role"
              options={@roles}
            />

            <.yes_no
              name="employee[active]"
              label="Active Status"
              value={Phoenix.HTML.Form.input_value(@form, :active)}
            />

            <.input
              type="number"
              field={@form[:salary]}
              label="Salary"
              placeholder="75000"
              step="1000"
              min="0"
            />
          </div>

          <:actions>
            <.button type="submit" variant="primary" size="lg">
              <%= if @action == :new, do: "Create Employee", else: "Update Employee" %>
            </.button>

            <.link patch={~p"/employees"}>
              <.button type="button" variant="outline" size="lg">
                Cancel
              </.button>
            </.link>
          </:actions>
        </.simple_form>
      </.form_container>
    </div>
    """
  end
end
