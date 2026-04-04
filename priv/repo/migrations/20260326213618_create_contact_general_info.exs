defmodule SnippetSaver.Repo.Migrations.CreateContactGeneralInfo do
  use Ecto.Migration

  def change do
    create table(:contact_general_info) do
      add :hospital, :string
      add :website, :string
      add :pet_insurance_supplier, :string
      add :date_of_birth, :date
      add :driver_license_number, :string
      add :driver_license_issuer, :string
      add :driver_license_expiry, :date
      add :national_id_number, :string
      add :passport_number, :string
      add :credit_limit_name, :string
      add :contact_details_confirmed, :boolean, default: false, null: false
      add :consolidate_invoices, :boolean, default: false, null: false
      add :contact_id, references(:contacts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:contact_general_info, [:contact_id],
             name: :contact_general_info_contact_id_index
           )
  end
end
