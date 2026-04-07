defmodule SnippetSaver.Repo.Migrations.CreatePatientMasterProblems do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:patient_master_problems) do
      add :notes, :text
      add :patient_id, references(:patients, on_delete: :nothing)
      add :master_problem_template_id, references(:master_problem_templates, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:patient_master_problems, [:patient_id])
    create_if_not_exists index(:patient_master_problems, [:master_problem_template_id])
  end
end
