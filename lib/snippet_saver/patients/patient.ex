defmodule SnippetSaver.Patients.Patient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patients" do
    field :patient_name, :string
    field :code, :string
    field :microchip_number, :string
    field :weight, :decimal
    field :weight_unit, :string
    field :age, :integer
    field :age_estimated, :boolean, default: false
    field :date_of_birth, :date
    field :sex, :string
    field :resuscitate, :string
    field :bill_to_other, :boolean, default: false
    field :is_animal_group, :boolean, default: false
    field :lives_away_from_owner, :boolean, default: false
    field :insurance_supplier_id, :integer
    field :insurance_number, :string
    field :general_tags, :map
    field :reminder_tags, :map
    field :owner_contact_id, :id
    field :species_id, :id
    field :breed_id, :id
    field :colour_id, :id
    field :preferred_doctor_contact_id, :id
    field :second_preferred_doctor_contact_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :patient_name,
      :code,
      :microchip_number,
      :weight,
      :weight_unit,
      :age,
      :age_estimated,
      :date_of_birth,
      :sex,
      :resuscitate,
      :bill_to_other,
      :is_animal_group,
      :lives_away_from_owner,
      :insurance_supplier_id,
      :insurance_number,
      :general_tags,
      :reminder_tags,
      :owner_contact_id,
      :species_id,
      :breed_id,
      :colour_id,
      :preferred_doctor_contact_id,
      :second_preferred_doctor_contact_id
    ])
    |> validate_required([:patient_name])
  end
end
