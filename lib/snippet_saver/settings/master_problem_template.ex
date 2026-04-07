defmodule SnippetSaver.Settings.MasterProblemTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "master_problem_templates" do
    field :name, :string
    field :description, :string
    field :archived, :boolean, default: false

    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(master_problem_template, attrs) do
    master_problem_template
    |> cast(attrs, [:name, :description, :archived])
    |> validate_required([:name, :description])
    |> validate_inclusion(:archived, [true, false])
  end
end
