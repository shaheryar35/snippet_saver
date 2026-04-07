defmodule SnippetSaver.Repo.Migrations.CreateAppointmentTypes do
  use Ecto.Migration

  def change do
    create table(:appointment_types) do
      add :name, :string
      add :duration_minutes, :integer
      add :color, :string
      add :is_active, :boolean, default: false, null: false
      add :inserted_by_id, references(:users, on_delete: :nothing)
      add :updated_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:appointment_types, [:inserted_by_id])
    create index(:appointment_types, [:updated_by_id])
  end
end
