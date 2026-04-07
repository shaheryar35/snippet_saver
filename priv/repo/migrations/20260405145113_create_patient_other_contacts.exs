defmodule SnippetSaver.Repo.Migrations.CreatePatientOtherContacts do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:patient_other_contacts) do
      add :patient_id, references(:patients, on_delete: :nothing)
      add :contact_id, references(:contacts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:patient_other_contacts, [:patient_id])
    create_if_not_exists index(:patient_other_contacts, [:contact_id])
  end
end
