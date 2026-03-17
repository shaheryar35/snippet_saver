defmodule SnippetSaverWeb.EmployeeLive.EmployeeRouter do
  @moduledoc """
  Route handling for the Employee LiveView: page detection, employee loading, and assigns.
  """
  import Phoenix.Component, only: [assign: 3]

  alias SnippetSaver.Employees
  alias SnippetSaver.Employees.Employee

  @doc """
  Handles params and URI, updates socket assigns for the current route.
  Returns `{:index, socket, params, path_segments}` for the list page (so Index can call apply_table_params),
  or `{:noreply, socket}` for show/edit/new.
  """
  def handle(params, uri, socket) do
    path = URI.parse(uri).path |> String.trim_leading("/") |> String.split("/")
    page = page_from_path(path)

    case page do
      :index ->
        {:index, socket, params, path}

      :new ->
        {:noreply,
         socket
         |> assign(:employee_page, :new)
         |> assign(:employee, %Employee{})
         |> assign(:page_title, "New Employee")
         |> assign(:active_page, "employees")}

      {:show, id} ->
        employee = Employees.get_employee!(id)
        socket =
          socket
          |> assign(:employee_page, :show)
          |> assign(:employee, employee)
          |> assign(:page_title, employee.name)
          |> assign(:active_page, "employees")
        {:noreply, socket}

      {:edit, id} ->
        employee = Employees.get_employee!(id)
        socket =
          socket
          |> assign(:employee_page, :edit)
          |> assign(:employee, employee)
          |> assign(:page_title, "Edit Employee")
          |> assign(:active_page, "employees")
        {:noreply, socket}

      {:show_subtab, id, subtab} ->
        employee = Employees.get_employee!(id)

        active_subtab =
          case subtab do
            "details" -> :details
            "activity" -> :activity
            "permissions" -> :permissions
            _ -> :details
          end

        socket =
          socket
          |> assign(:employee_page, :show)
          |> assign(:employee, employee)
          |> assign(:active_subtab, active_subtab)
          |> assign(:page_title, employee.name)
          |> assign(:active_page, "employees")

        {:noreply, socket}
    end
  end

  defp page_from_path(["employees"]), do: :index

  defp page_from_path(["employees" | rest]) do
    case rest do
      [] -> :index
      ["new"] -> :new
      [id, "edit"] -> {:edit, String.to_integer(id)}
      [id] -> {:show, String.to_integer(id)}
      [id, subtab] -> {:show_subtab, String.to_integer(id), subtab}
      _ -> :index
    end
  end

  defp page_from_path(_), do: :index
end
