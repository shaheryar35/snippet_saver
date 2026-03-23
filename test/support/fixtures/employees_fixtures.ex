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

  @doc """
  Generate a unique permission name.
  """
  def unique_permission_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a permission.
  """
  def permission_fixture(attrs \\ %{}) do
    {:ok, permission} =
      attrs
      |> Enum.into(%{
        action: "some action",
        description: "some description",
        name: unique_permission_name(),
        resource: "some resource"
      })
      |> SnippetSaver.Employees.create_permission()

    permission
  end

  @doc """
  Generate a activity.
  """
  def activity_fixture(attrs \\ %{}) do
    {:ok, activity} =
      attrs
      |> Enum.into(%{
        action: "some action",
        details: %{},
        ip_address: "some ip_address",
        resource_id: 42,
        resource_type: "some resource_type",
        user_agent: "some user_agent"
      })
      |> SnippetSaver.Employees.create_activity()

    activity
  end
end
