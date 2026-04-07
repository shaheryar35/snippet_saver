defmodule SnippetSaver.Repo.Migrations.AddArchivedToAppointmentTypesAndStatus do
  use Ecto.Migration

  def change do
    alter table(:appointment_types) do
      add :archived, :boolean, default: false, null: false
    end

    alter table(:appointment_status) do
      add :archived, :boolean, default: false, null: false
    end
  end
end
