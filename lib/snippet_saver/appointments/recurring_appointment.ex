defmodule SnippetSaver.Appointments.RecurringAppointment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recurring_appointments" do
    field :next_due_date, :date
    field :interval_days, :integer
    field :reminder_days_before, :integer
    field :is_active, :boolean, default: false

    belongs_to :patient, SnippetSaver.Patients.Patient
    belongs_to :owner_contact, SnippetSaver.Contacts.Contact, foreign_key: :owner_contact_id
    belongs_to :doctor_contact, SnippetSaver.Contacts.Contact, foreign_key: :doctor_contact_id
    belongs_to :appointment_type, SnippetSaver.Settings.AppointmentType

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recurring_appointment, attrs) do
    recurring_appointment
    |> cast(attrs, [
      :next_due_date,
      :interval_days,
      :reminder_days_before,
      :is_active,
      :patient_id,
      :owner_contact_id,
      :doctor_contact_id,
      :appointment_type_id
    ])
    |> validate_required([:next_due_date, :interval_days, :reminder_days_before, :is_active])
    |> validate_inclusion(:is_active, [true, false])
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:owner_contact_id)
    |> foreign_key_constraint(:doctor_contact_id)
    |> foreign_key_constraint(:appointment_type_id)
  end
end
