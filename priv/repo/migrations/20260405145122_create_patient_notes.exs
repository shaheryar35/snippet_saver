defmodule SnippetSaver.Repo.Migrations.CreatePatientNotes do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:patient_notes) do
      add :notes, :text
      add :notes_important, :boolean, default: false, null: false
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:patient_notes, [:patient_id])
  end
end
