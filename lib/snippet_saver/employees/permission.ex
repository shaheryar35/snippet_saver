defmodule SnippetSaver.Employees.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :resource, :string
    field :action, :string
    field :description, :string
    # Add relationships
    many_to_many :employees, SnippetSaver.Employees.Employee, join_through: "employee_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :resource, :action, :description])
    |> validate_required([:name, :resource, :action, :description])
    |> unique_constraint(:name)
  end
end
