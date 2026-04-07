defmodule SnippetSaver.Patients.PatientNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_notes" do
    field :notes, :string
    field :notes_important, :boolean, default: false
    field :patient_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient_note, attrs) do
    patient_note
    |> cast(attrs, [:notes, :notes_important])
    |> validate_required([:notes, :notes_important])
  end
end
