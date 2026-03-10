defmodule SnippetSaver.EmployeesTest do
  use SnippetSaver.DataCase

  alias SnippetSaver.Employees

  describe "employees" do
    alias SnippetSaver.Employees.Employee

    import SnippetSaver.EmployeesFixtures

    @invalid_attrs %{active: nil, name: nil, role: nil, email: nil, company: nil, department: nil, salary: nil}

    test "list_employees/0 returns all employees" do
      employee = employee_fixture()
      assert Employees.list_employees() == [employee]
    end

    test "get_employee!/1 returns the employee with given id" do
      employee = employee_fixture()
      assert Employees.get_employee!(employee.id) == employee
    end

    test "create_employee/1 with valid data creates a employee" do
      valid_attrs = %{active: true, name: "some name", role: "some role", email: "some email", company: "some company", department: "some department", salary: "120.5"}

      assert {:ok, %Employee{} = employee} = Employees.create_employee(valid_attrs)
      assert employee.active == true
      assert employee.name == "some name"
      assert employee.role == "some role"
      assert employee.email == "some email"
      assert employee.company == "some company"
      assert employee.department == "some department"
      assert employee.salary == Decimal.new("120.5")
    end

    test "create_employee/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Employees.create_employee(@invalid_attrs)
    end

    test "update_employee/2 with valid data updates the employee" do
      employee = employee_fixture()
      update_attrs = %{active: false, name: "some updated name", role: "some updated role", email: "some updated email", company: "some updated company", department: "some updated department", salary: "456.7"}

      assert {:ok, %Employee{} = employee} = Employees.update_employee(employee, update_attrs)
      assert employee.active == false
      assert employee.name == "some updated name"
      assert employee.role == "some updated role"
      assert employee.email == "some updated email"
      assert employee.company == "some updated company"
      assert employee.department == "some updated department"
      assert employee.salary == Decimal.new("456.7")
    end

    test "update_employee/2 with invalid data returns error changeset" do
      employee = employee_fixture()
      assert {:error, %Ecto.Changeset{}} = Employees.update_employee(employee, @invalid_attrs)
      assert employee == Employees.get_employee!(employee.id)
    end

    test "delete_employee/1 deletes the employee" do
      employee = employee_fixture()
      assert {:ok, %Employee{}} = Employees.delete_employee(employee)
      assert_raise Ecto.NoResultsError, fn -> Employees.get_employee!(employee.id) end
    end

    test "change_employee/1 returns a employee changeset" do
      employee = employee_fixture()
      assert %Ecto.Changeset{} = Employees.change_employee(employee)
    end
  end
end
