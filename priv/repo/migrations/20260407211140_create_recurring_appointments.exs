defmodule SnippetSaver.Repo.Migrations.CreateRecurringAppointments do
  use Ecto.Migration

  def change do
    create table(:recurring_appointments) do
      add :next_due_date, :date
      add :interval_days, :integer
      add :reminder_days_before, :integer
      add :is_active, :boolean, default: false, null: false
      add :patient_id, references(:patients, on_delete: :nothing)
      add :owner_contact_id, references(:contacts, on_delete: :nothing)
      add :doctor_contact_id, references(:contacts, on_delete: :nothing)
      add :appointment_type_id, references(:appointment_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:recurring_appointments, [:patient_id])
    create index(:recurring_appointments, [:owner_contact_id])
    create index(:recurring_appointments, [:doctor_contact_id])
    create index(:recurring_appointments, [:appointment_type_id])
  end
end
