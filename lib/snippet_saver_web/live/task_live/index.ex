defmodule SnippetSaverWeb.TaskLive.Index do
  use SnippetSaverWeb, :live_view

  alias SnippetSaver.Tasks
  alias SnippetSaver.Tasks.Task

  def mount(_params, _session, socket) do
    tasks = Tasks.list_tasks()
    changeset = Tasks.change_task(%Task{})
    editing_task_id = nil
    edit_changeset = nil

    {:ok,
     assign(socket,
       tasks: tasks,
       changeset: changeset,
       # Missing
       editing_task_id: editing_task_id,
       # Missing
       edit_changeset: edit_changeset
     )}
  end

  def handle_event("create", %{"task" => task_params}, socket) do
    case Tasks.create_task(task_params) do
      # Prefix with underscore since we're not using it
      {:ok, _task} ->
        tasks = Tasks.list_tasks()
        changeset = Tasks.change_task(%Task{})

        {:noreply,
         assign(socket,
           tasks: tasks,
           changeset: changeset,
           # Add this
           editing_task_id: nil,
           # Add this
           edit_changeset: nil
         )}

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
    <h1>Tasks</h1>

    <!-- Create Task Form -->
    <.form
      for={@changeset}
      phx-submit="create"
    >
      <div>
        <label>Name</label>
        <input
          type="text"
          name="task[name]"
          value={Ecto.Changeset.get_field(@changeset, :name)}
        />
        <%= error_tag(@changeset, :name) %>
      </div>

      <div>
        <label>Description</label>
        <textarea name="task[description]"><%= Ecto.Changeset.get_field(@changeset, :description) %></textarea>
        <%= error_tag(@changeset, :description) %>
      </div>

      <div>
        <label>User ID</label>
        <input
          type="text"
          name="task[user_id]"
          value={Ecto.Changeset.get_field(@changeset, :user_id)}
        />
        <%= error_tag(@changeset, :user_id) %>
      </div>

      <div>
        <button type="submit">Create Task</button>
      </div>
    </.form>

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
            >
              <div>
                <label>Name</label>
                <input
                  type="text"
                  name="task[name]"
                  value={Ecto.Changeset.get_field(@edit_changeset, :name)}
                />
                <%= error_tag(@edit_changeset, :name) %>
              </div>

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
                <button type="submit">Save Changes</button>
                <button type="button" phx-click="cancel_edit">Cancel</button>
              </div>
            </.form>
          <% else %>
            <!-- Display task with Edit and Delete buttons -->
            <strong><%= task.name %></strong> —
            <%= task.description %>
            (User: <%= task.user_id %>)
            <button
              type="button"
              phx-click="edit"
              phx-value-id={task.id}
              class="edit-btn"
            >
              Edit
            </button>
            <button
              type="button"
              phx-click="delete"
              phx-value-id={task.id}
              class="delete-btn"
            >
              Delete
            </button>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  # Define error_tag as a simple function that returns a string
  defp error_tag(changeset, field) do
    case changeset.errors[field] do
      nil ->
        ""

      {message, _opts} ->
        assigns = %{message: message}
        ~H"<span class=\"error\"><%= @message %></span>"
    end
  end
end
