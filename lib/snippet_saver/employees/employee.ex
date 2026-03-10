defmodule SnippetSaver.Employees.Employee do
  use Ecto.Schema
  import Ecto.Changeset

  schema "employees" do
    field :active, :boolean, default: false
    field :name, :string
    field :role, :string
    field :email, :string
    field :company, :string
    field :department, :string
    field :salary, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [:name, :email, :company, :department, :role, :active, :salary])
    |> validate_required([:name, :email, :company], message: "is required")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    |> validate_length(:name, min: 2, message: "must be at least 2 characters")
    |> validate_number(:salary, greater_than: 0, message: "must be greater than 0")
  end
end
