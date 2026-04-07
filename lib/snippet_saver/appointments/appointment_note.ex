defmodule SnippetSaver.Appointments.AppointmentNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appointment_notes" do
    field :notes, :string

    belongs_to :appointment, SnippetSaver.Appointments.Appointment
    belongs_to :created_by_user, SnippetSaver.Accounts.User, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(appointment_note, attrs) do
    appointment_note
    |> cast(attrs, [:notes, :created_by, :appointment_id])
    |> validate_required([:notes, :created_by])
    |> foreign_key_constraint(:appointment_id)
  end
end
