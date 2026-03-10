defmodule SnippetSaver.EmployeesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SnippetSaver.Employees` context.
  """

  @doc """
  Generate a employee.
  """
  def employee_fixture(attrs \\ %{}) do
    {:ok, employee} =
      attrs
      |> Enum.into(%{
        active: true,
        company: "some company",
        department: "some department",
        email: "some email",
        name: "some name",
        role: "some role",
        salary: "120.5"
      })
      |> SnippetSaver.Employees.create_employee()

    employee
  end
end
