defmodule SnippetSaver.Repo.Migrations.CreateMasterProblemTemplates do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:master_problem_templates) do
      add :name, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
