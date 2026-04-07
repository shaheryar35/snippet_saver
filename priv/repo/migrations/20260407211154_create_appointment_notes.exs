defmodule SnippetSaver.Repo.Migrations.CreateAppointmentNotes do
  use Ecto.Migration

  def change do
    create table(:appointment_notes) do
      add :notes, :text
      add :created_by, :integer
      add :appointment_id, references(:appointments, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:appointment_notes, [:appointment_id])
  end
end
