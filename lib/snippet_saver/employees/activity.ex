defmodule SnippetSaver.Employees.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :integer
    field :details, :map
    field :ip_address, :string
    field :user_agent, :string
    belongs_to :employee, SnippetSaver.Employees.Employee

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:action, :resource_type, :resource_id, :details, :ip_address, :user_agent])
    |> validate_required([:employee_id, :action, :resource_type])
    |> foreign_key_constraint(:employee_id)
  end
end
