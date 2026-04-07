defmodule SnippetSaver.Patients.PatientOtherContact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_other_contacts" do

    field :patient_id, :id
    field :contact_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient_other_contact, attrs) do
    patient_other_contact
    |> cast(attrs, [])
    |> validate_required([])
  end
end
