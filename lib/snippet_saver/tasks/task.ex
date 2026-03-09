defmodule SnippetSaver.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :name, :string
    field :description, :string
    field :user_id, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name], message: "Please enter a task name")
  end
end
