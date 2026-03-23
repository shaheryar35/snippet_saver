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

  describe "permissions" do
    alias SnippetSaver.Employees.Permission

    import SnippetSaver.EmployeesFixtures

    @invalid_attrs %{name: nil, description: nil, resource: nil, action: nil}

    test "list_permissions/0 returns all permissions" do
      permission = permission_fixture()
      assert Employees.list_permissions() == [permission]
    end

    test "get_permission!/1 returns the permission with given id" do
      permission = permission_fixture()
      assert Employees.get_permission!(permission.id) == permission
    end

    test "create_permission/1 with valid data creates a permission" do
      valid_attrs = %{name: "some name", description: "some description", resource: "some resource", action: "some action"}

      assert {:ok, %Permission{} = permission} = Employees.create_permission(valid_attrs)
      assert permission.name == "some name"
      assert permission.description == "some description"
      assert permission.resource == "some resource"
      assert permission.action == "some action"
    end

    test "create_permission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Employees.create_permission(@invalid_attrs)
    end

    test "update_permission/2 with valid data updates the permission" do
      permission = permission_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", resource: "some updated resource", action: "some updated action"}

      assert {:ok, %Permission{} = permission} = Employees.update_permission(permission, update_attrs)
      assert permission.name == "some updated name"
      assert permission.description == "some updated description"
      assert permission.resource == "some updated resource"
      assert permission.action == "some updated action"
    end

    test "update_permission/2 with invalid data returns error changeset" do
      permission = permission_fixture()
      assert {:error, %Ecto.Changeset{}} = Employees.update_permission(permission, @invalid_attrs)
      assert permission == Employees.get_permission!(permission.id)
    end

    test "delete_permission/1 deletes the permission" do
      permission = permission_fixture()
      assert {:ok, %Permission{}} = Employees.delete_permission(permission)
      assert_raise Ecto.NoResultsError, fn -> Employees.get_permission!(permission.id) end
    end

    test "change_permission/1 returns a permission changeset" do
      permission = permission_fixture()
      assert %Ecto.Changeset{} = Employees.change_permission(permission)
    end
  end

  describe "activities" do
    alias SnippetSaver.Employees.Activity

    import SnippetSaver.EmployeesFixtures

    @invalid_attrs %{action: nil, details: nil, resource_type: nil, resource_id: nil, ip_address: nil, user_agent: nil}

    test "list_activities/0 returns all activities" do
      activity = activity_fixture()
      assert Employees.list_activities() == [activity]
    end

    test "get_activity!/1 returns the activity with given id" do
      activity = activity_fixture()
      assert Employees.get_activity!(activity.id) == activity
    end

    test "create_activity/1 with valid data creates a activity" do
      valid_attrs = %{action: "some action", details: %{}, resource_type: "some resource_type", resource_id: 42, ip_address: "some ip_address", user_agent: "some user_agent"}

      assert {:ok, %Activity{} = activity} = Employees.create_activity(valid_attrs)
      assert activity.action == "some action"
      assert activity.details == %{}
      assert activity.resource_type == "some resource_type"
      assert activity.resource_id == 42
      assert activity.ip_address == "some ip_address"
      assert activity.user_agent == "some user_agent"
    end

    test "create_activity/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Employees.create_activity(@invalid_attrs)
    end

    test "update_activity/2 with valid data updates the activity" do
      activity = activity_fixture()
      update_attrs = %{action: "some updated action", details: %{}, resource_type: "some updated resource_type", resource_id: 43, ip_address: "some updated ip_address", user_agent: "some updated user_agent"}

      assert {:ok, %Activity{} = activity} = Employees.update_activity(activity, update_attrs)
      assert activity.action == "some updated action"
      assert activity.details == %{}
      assert activity.resource_type == "some updated resource_type"
      assert activity.resource_id == 43
      assert activity.ip_address == "some updated ip_address"
      assert activity.user_agent == "some updated user_agent"
    end

    test "update_activity/2 with invalid data returns error changeset" do
      activity = activity_fixture()
      assert {:error, %Ecto.Changeset{}} = Employees.update_activity(activity, @invalid_attrs)
      assert activity == Employees.get_activity!(activity.id)
    end

    test "delete_activity/1 deletes the activity" do
      activity = activity_fixture()
      assert {:ok, %Activity{}} = Employees.delete_activity(activity)
      assert_raise Ecto.NoResultsError, fn -> Employees.get_activity!(activity.id) end
    end

    test "change_activity/1 returns a activity changeset" do
      activity = activity_fixture()
      assert %Ecto.Changeset{} = Employees.change_activity(activity)
    end
  end
end
