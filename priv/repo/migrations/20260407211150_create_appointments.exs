defmodule SnippetSaver.Repo.Migrations.CreateAppointments do
  use Ecto.Migration

  def change do
    create table(:appointments) do
      add :appointment_datetime, :utc_datetime
      add :duration_minutes, :integer
      add :reason, :text
      add :room, :string
      add :created_by, :integer
      add :updated_by, :integer
      add :patient_id, references(:patients, on_delete: :nothing)
      add :owner_contact_id, references(:contacts, on_delete: :nothing)
      add :doctor_contact_id, references(:contacts, on_delete: :nothing)
      add :appointment_type_id, references(:appointment_types, on_delete: :nothing)
      add :appointment_status_id, references(:appointment_status, on_delete: :nothing)
      add :recurring_appointment_id, references(:recurring_appointments, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:appointments, [:patient_id])
    create index(:appointments, [:owner_contact_id])
    create index(:appointments, [:doctor_contact_id])
    create index(:appointments, [:appointment_type_id])
    create index(:appointments, [:appointment_status_id])
    create index(:appointments, [:recurring_appointment_id])
  end
end
