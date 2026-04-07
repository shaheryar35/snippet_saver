defmodule SnippetSaver.Repo.Migrations.CreateAppointmentStatus do
  use Ecto.Migration

  def change do
    create table(:appointment_status) do
      add :name, :string
      add :color, :string
      add :inserted_by_id, references(:users, on_delete: :nothing)
      add :updated_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:appointment_status, [:inserted_by_id])
    create index(:appointment_status, [:updated_by_id])
  end
end
