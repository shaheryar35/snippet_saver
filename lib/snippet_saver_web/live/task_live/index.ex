defmodule SnippetSaverWeb.TaskLive.Index do
  use SnippetSaverWeb, :live_view

  alias SnippetSaver.Tasks
  alias SnippetSaver.Tasks.Task

  def mount(_params, _session, socket) do
    tasks = Tasks.list_tasks()
    changeset = Tasks.change_task(%Task{})
    editing_task_id = nil
    edit_changeset = nil
    tags = ["work", "urgent"]

    {:ok,
     assign(socket,
       tasks: tasks,
       changeset: changeset,
       editing_task_id: editing_task_id,
       edit_changeset: edit_changeset,
       tags: tags,
       active_page: "tasks"
     )}
  end

  def handle_event("validate", %{"task" => task_params}, socket) do
    tags = List.wrap(task_params["tags"] || [])
    # Don't set action: :validate - we only show errors after submit (via error_tag)
    changeset = Task.changeset(%Task{}, task_params)

    {:noreply,
     assign(socket,
       changeset: changeset,
       tags: tags
     )}
  end

  # def handle_event("create", %{"task" => task_params}, socket) do
  #   case Tasks.create_task(task_params) do
  #     # Prefix with underscore since we're not using it
  #     {:ok, _task} ->
  #       tasks = Tasks.list_tasks()
  #       changeset = Tasks.change_task(%Task{})

  #       {:noreply,
  #        assign(socket,
  #          tasks: tasks,
  #          changeset: changeset,
  #          editing_task_id: nil,
  #          edit_changeset: nil,
  #          tags: []
  #        )}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end

  def handle_event("create", %{"task" => task_params}, socket) do
    IO.inspect(task_params, label: "🔵 FORM SUBMITTED - ALL VALUES")

    # Format the params as a readable string
    params_preview =
      task_params
      |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
      |> Enum.join(", ")

    case Tasks.create_task(task_params) do
      {:ok, _task} ->
        tasks = Tasks.list_tasks()
        changeset = Tasks.change_task(%Task{})

        socket =
          socket
          |> assign(
            tasks: tasks,
            changeset: changeset,
            editing_task_id: nil,
            edit_changeset: nil,
            tags: []
          )
          |> put_flash(:info, "Task created! Values: #{params_preview}")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # Add delete event handler
  # def handle_event("delete", %{"id" => id}, socket) do
  #   task = Tasks.get_task!(id)

  #   case Tasks.delete_task(task) do
  #     {:ok, _task} ->
  #       tasks = Tasks.list_tasks()
  #       {:noreply, assign(socket, tasks: tasks)}

  #     {:error, _reason} ->
  #       # Handle error case - you might want to add a flash message here
  #       {:noreply, socket}
  #   end
  # end

  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)

    case Tasks.delete_task(task) do
      {:ok, _task} ->
        tasks = Tasks.list_tasks()

        socket =
          socket
          |> assign(tasks: tasks)
          |> put_flash(:info, "Task deleted successfully")

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete task")}
    end
  end

  # Start editing a task
  def handle_event("edit", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    changeset = Tasks.change_task(task)

    {:noreply,
     assign(socket,
       editing_task_id: id,
       edit_changeset: changeset
     )}
  end

  # Cancel editing
  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_task_id: nil, edit_changeset: nil)}
  end

  def handle_event("clear_test_form", _, socket) do
    {:noreply, socket}
  end

  # Update task
  def handle_event("update", %{"task" => task_params, "id" => id}, socket) do
    task = Tasks.get_task!(id)

    case Tasks.update_task(task, task_params) do
      {:ok, _task} ->
        tasks = Tasks.list_tasks()

        {:noreply,
         assign(socket,
           tasks: tasks,
           editing_task_id: nil,
           edit_changeset: nil
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, edit_changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <%!-- <h1>Tasks</h1> --%>

    <!-- Create Task Form -->
    <.form_container title="Create New Task - Test All Inputs">
    <.form
    for={@changeset}
    phx-change="validate"
    phx-submit="create"
    novalidate
    >
    <!-- ===== TEXT INPUTS ===== -->
    <h3 class="text-lg font-semibold mt-4 mb-2 text-gray-700">📝 Text Inputs</h3>

    <!-- Regular Text Input -->
    <.input
      type="text"
      name="task[name]"
      label="Name (text)"
      value={Ecto.Changeset.get_field(@changeset, :name)}
      errors={error_tag(@changeset, :name)}
      size="md"
      placeholder="Enter task name"
      required
    />

    <!-- Small Text Input -->
    <.input
      type="text"
      name="task[name_small]"
      label="Name (small size)"
      value={Ecto.Changeset.get_field(@changeset, :name)}
      errors={error_tag(@changeset, :name)}
      size="sm"
      placeholder="Small input"
    />

    <!-- Large Text Input -->
    <.input
      type="text"
      name="task[name_large]"
      label="Name (large size)"
      value={Ecto.Changeset.get_field(@changeset, :name)}
      errors={error_tag(@changeset, :name)}
      size="lg"
      placeholder="Large input"
    />

    <.multi_select_dropdown
      name="task[tags]"
      label="Select tags"
      options={[{"Work", "work"}, {"Personal", "personal"}, {"Urgent", "urgent"}]}
      value={@tags}
      placeholder="Choose tags..."
    />

    <.switch name="task[active]" label="Enable notifications" checked={true} />
    <.yes_no name="task[confirmed]" label="Confirmed?" value={true} />
    <.radio_group
    name="task[priority]"
    label="Priority"
    options={[{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}]}
    value="medium"
    />

    <!-- Email Input -->
    <.input
      type="email"
      name="task[email]"
      label="Email Address"
      value="test@example.com"
      placeholder="Enter email"
    />

    <!-- Password Input -->
    <.input
      type="password"
      name="task[password]"
      label="Password"
      value="secret123"
      placeholder="Enter password"
    />

    <!-- Number Input -->
    <.input
      type="number"
      name="task[number]"
      label="Age"
      value={25}
      min="0"
      max="120"
      step="1"
    />

    <!-- Telephone Input -->
    <.input
      type="tel"
      name="task[phone]"
      label="Phone Number"
      value="+1 234 567 8900"
      placeholder="(123) 456-7890"
    />

    <!-- URL Input -->
    <.input
      type="url"
      name="task[website]"
      label="Website"
      value="https://example.com"
      placeholder="https://..."
    />

    <!-- ===== DATE/TIME INPUTS ===== -->
    <h3 class="text-lg font-semibold mt-6 mb-2 text-gray-700">📅 Date & Time Inputs</h3>

    <!-- Date Input -->
    <.input
      type="date"
      name="task[date]"
      label="Date"
      value="2024-03-15"
    />

    <!-- Time Input -->
    <.input
      type="time"
      name="task[time]"
      label="Time"
      value="14:30"
    />

    <!-- DateTime-Local Input -->
    <.input
      type="datetime-local"
      name="task[datetime]"
      label="Date and Time"
      value="2024-03-15T14:30"
    />

    <!-- Month Input -->
    <.input
      type="month"
      name="task[month]"
      label="Month"
      value="2024-03"
    />

    <!-- Week Input -->
    <.input
      type="week"
      name="task[week]"
      label="Week"
      value="2024-W11"
    />

    <!-- ===== SPECIAL INPUTS ===== -->
    <h3 class="text-lg font-semibold mt-6 mb-2 text-gray-700">🎨 Special Inputs</h3>

    <!-- Color Input -->
    <.input
      type="color"
      name="task[color]"
      label="Favorite Color"
      value="#3b82f6"
    />

    <!-- Range Input -->
    <.input
      type="range"
      name="task[range]"
      label="Volume"
      value={50}
      min="0"
      max="100"
    />

    <!-- ===== TEXTAREA ===== -->
    <h3 class="text-lg font-semibold mt-6 mb-2 text-gray-700">📄 Textarea</h3>

    <!-- Regular Textarea -->
    <.input
      type="textarea"
      name="task[description]"
      label="Description (textarea)"
      value={Ecto.Changeset.get_field(@changeset, :description)}
      errors={error_tag(@changeset, :description)}
      rows={4}
      placeholder="Enter detailed description..."
    />

    <!-- Small Textarea -->
    <.input
      type="textarea"
      name="task[description_small]"
      label="Small Textarea"
      value="Small description"
      size="sm"
      rows={2}
    />

    <!-- Large Textarea -->
    <.input
      type="textarea"
      name="task[description_large]"
      label="Large Textarea"
      value="Large description with more space"
      size="lg"
      rows={6}
    />

    <!-- ===== SELECT DROPDOWNS ===== -->
    <h3 class="text-lg font-semibold mt-6 mb-2 text-gray-700">🔽 Select Dropdowns</h3>

    <!-- Regular Select -->
    <.input
      type="select"
      name="task[priority]"
      label="Priority"
      value="medium"
    >
      <option value="">-- Select Priority --</option>
      <option value="low">Low</option>
      <option value="medium" selected>Medium</option>
      <option value="high">High</option>
      <option value="urgent">Urgent</option>
    </.input>

    <!-- Select with Error -->
    <.input
      type="select"
      name="task[status]"
      label="Status"
      value=""
      errors={["please select a status"]}
    >
      <option value="">-- Select Status --</option>
      <option value="pending">Pending</option>
      <option value="in_progress">In Progress</option>
      <option value="completed">Completed</option>
    </.input>

    <!-- Small Select -->
    <.input
      type="select"
      name="task[category_small]"
      label="Category (small)"
      size="sm"
      value="work"
    >
      <option value="work">Work</option>
      <option value="personal">Personal</option>
      <option value="other">Other</option>
    </.input>

    <!-- ===== USER ID FIELD (original) ===== -->
    <h3 class="text-lg font-semibold mt-6 mb-2 text-gray-700">👤 User Information</h3>

    <.input
      type="text"
      name="task[user_id]"
      label="User ID"
      value={Ecto.Changeset.get_field(@changeset, :user_id)}
      errors={error_tag(@changeset, :user_id)}
      placeholder="Enter user ID"
    />

    <!-- ===== ERROR STATES EXAMPLE ===== -->
    <h3 class="text-lg font-semibold mt-6 mb-2 text-gray-700">⚠️ Error State Examples</h3>

    <!-- Text with Error -->
    <.input
      type="text"
      name="task[error_example]"
      label="Field with Error"
      value=""
      errors={["can't be blank", "must be at least 3 characters"]}
      placeholder="This shows multiple errors"
    />

    <!-- Textarea with Error -->
    <.input
      type="textarea"
      name="task[error_textarea]"
      label="Textarea with Error"
      value=""
      errors={["description is required"]}
      rows={3}
    />

    <!-- ===== FORM ACTIONS ===== -->
    <.form_actions>
      <.button type="submit" variant="primary" size="lg">
        Create Task
      </.button>
      <.button type="button" variant="outline" size="lg" phx-click="clear_test_form">
        Clear Test
      </.button>
    </.form_actions>
    </.form>
    </.form_container>

    <hr />

    <!-- List Tasks with Edit Functionality -->
    <ul>
      <%= for task <- @tasks do %>
        <li>
          <%!-- <%= if @editing_task_id == task.id do %> --%>
          <%= if @editing_task_id && to_string(@editing_task_id) == to_string(task.id) do %>
            <!-- Edit Form for this task -->
            <.form
              for={@edit_changeset}
              phx-submit="update"
              phx-value-id={task.id}
              novalidate
            >
              <%!-- <div>
                <label>Name</label>
                <input
                  type="text"
                  name="task[name]"
                  value={Ecto.Changeset.get_field(@edit_changeset, :name)}
                />
                <%= error_tag(@edit_changeset, :name) %>
              </div> --%>
    <%!-- <label>Name</label> --%>
                <.input
                type="text"
                name="task[name]"
                label="Namesss"
                value={Ecto.Changeset.get_field(@edit_changeset, :name)}
                errors={error_tag(@edit_changeset, :name)}
                size="lg"
                required={true}
                />

              <div>
                <label>Description</label>
                <textarea name="task[description]"><%= Ecto.Changeset.get_field(@edit_changeset, :description) %></textarea>
                <%= error_tag(@edit_changeset, :description) %>
              </div>

              <div>
                <label>User ID</label>
                <input
                  type="text"
                  name="task[user_id]"
                  value={Ecto.Changeset.get_field(@edit_changeset, :user_id)}
                />
                <%= error_tag(@edit_changeset, :user_id) %>
              </div>

              <div>
              <.button type="submit" variant="primary">
              Save Changes
              </.button>

              <!-- Cancel button - outline variant, button type, with phx-click -->
              <.button type="button" variant="outline" phx-click="cancel_edit">
              Cancel
              </.button>
              </div>
            </.form>
          <% else %>
            <!-- Display task with Edit and Delete buttons -->
            <strong><%= task.name %></strong> —
            <%= task.description %>
            (User: <%= task.user_id %>)
            <.button
              type="button"
              phx-click="edit"
              phx-value-id={task.id}
              variant="primary"
            >
              Edit
            </.button>

    <%!-- <button type="button" phx-click="edit" phx-value-id={task.id}>
    Edit (Test)
    </button> --%>
            <.button
              type="button"
              phx-click="delete"
              phx-value-id={task.id}
              variant="danger"
            >
              Delete
            </.button>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  # Define error_tag as a simple function that returns a string
  # BLEW THAT WAS RETURNING HTMML
  # defp error_tag(changeset, field) do
  #   case changeset.errors[field] do
  #     nil ->
  #       ""

  #     {message, _opts} ->
  #       assigns = %{message: message}
  #       ~H"<span class=\"error\"><%= @message %></span>"
  #   end
  # end

  defp error_tag(changeset, field) do
    # Only show errors after user has attempted to submit (changeset.action is set)
    if changeset.action do
      case changeset.errors[field] do
        nil -> []
        {message, _opts} -> [message]
      end
    else
      []
    end
  end
end
