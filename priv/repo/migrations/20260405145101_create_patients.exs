defmodule SnippetSaver.Repo.Migrations.CreatePatients do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:patients) do
      add :patient_name, :string
      add :code, :string
      add :microchip_number, :string
      add :weight, :decimal
      add :weight_unit, :string
      add :age, :integer
      add :age_estimated, :boolean, default: false, null: false
      add :date_of_birth, :date
      add :sex, :string
      add :resuscitate, :string
      add :bill_to_other, :boolean, default: false, null: false
      add :is_animal_group, :boolean, default: false, null: false
      add :lives_away_from_owner, :boolean, default: false, null: false
      add :insurance_supplier_id, :integer
      add :insurance_number, :string
      add :general_tags, :map
      add :reminder_tags, :map
      add :owner_contact_id, references(:contacts, on_delete: :nothing)
      add :species_id, references(:species, on_delete: :nothing)
      add :breed_id, references(:breeds, on_delete: :nothing)
      add :colour_id, references(:colours, on_delete: :nothing)
      add :preferred_doctor_contact_id, references(:contacts, on_delete: :nothing)
      add :second_preferred_doctor_contact_id, references(:contacts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:patients, [:owner_contact_id])
    create_if_not_exists index(:patients, [:species_id])
    create_if_not_exists index(:patients, [:breed_id])
    create_if_not_exists index(:patients, [:colour_id])
    create_if_not_exists index(:patients, [:preferred_doctor_contact_id])
    create_if_not_exists index(:patients, [:second_preferred_doctor_contact_id])
  end
end
