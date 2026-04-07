defmodule SnippetSaver.Appointments.Appointment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appointments" do
    field :appointment_datetime, :utc_datetime
    field :duration_minutes, :integer
    field :reason, :string
    field :room, :string

    belongs_to :patient, SnippetSaver.Patients.Patient
    belongs_to :owner_contact, SnippetSaver.Contacts.Contact, foreign_key: :owner_contact_id
    belongs_to :doctor_contact, SnippetSaver.Contacts.Contact, foreign_key: :doctor_contact_id
    belongs_to :appointment_type, SnippetSaver.Settings.AppointmentType
    belongs_to :appointment_status, SnippetSaver.Settings.AppointmentStatus
    belongs_to :recurring_appointment, SnippetSaver.Appointments.RecurringAppointment

    belongs_to :created_by_user, SnippetSaver.Accounts.User, foreign_key: :created_by
    belongs_to :updated_by_user, SnippetSaver.Accounts.User, foreign_key: :updated_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :appointment_datetime,
      :duration_minutes,
      :reason,
      :room,
      :created_by,
      :updated_by,
      :patient_id,
      :owner_contact_id,
      :doctor_contact_id,
      :appointment_type_id,
      :appointment_status_id,
      :recurring_appointment_id
    ])
    |> validate_required([
      :appointment_datetime,
      :duration_minutes,
      :reason,
      :room,
      :created_by,
      :updated_by
    ])
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:owner_contact_id)
    |> foreign_key_constraint(:doctor_contact_id)
    |> foreign_key_constraint(:appointment_type_id)
    |> foreign_key_constraint(:appointment_status_id)
    |> foreign_key_constraint(:recurring_appointment_id)
  end
end
