defmodule SnippetSaverWeb.TasksController do
  use SnippetSaverWeb, :controller
  alias SnippetSaver.Tasks
  alias SnippetSaver.Tasks.Task

  def main(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    tasks = Tasks.list_tasks()
    changeset = Task.changeset(%Task{}, %{})
    render(conn, :main, tasks: tasks, changeset: changeset)
    # render(conn, :main, layout: false)
  end

  def create(conn, %{"task" => task_params}) do
    case Tasks.create_task(task_params) do
      {:ok, _task} ->
        redirect(conn, to: ~p"/tasks")

      {:error, changeset} ->
        tasks = Tasks.list_tasks()
        render(conn, :index, tasks: tasks, changeset: changeset)
    end
  end
end
