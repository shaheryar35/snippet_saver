defmodule SnippetSaver.Contacts.GeneralInfo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_general_info" do
    field :hospital, :string
    field :website, :string
    field :pet_insurance_supplier, :string
    field :date_of_birth, :date
    field :driver_license_number, :string
    field :driver_license_issuer, :string
    field :driver_license_expiry, :date
    field :national_id_number, :string
    field :passport_number, :string
    field :credit_limit_name, :string
    field :contact_details_confirmed, :boolean, default: false
    field :consolidate_invoices, :boolean, default: false

    # Associations
    belongs_to :contact, SnippetSaver.Contacts.Contact

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(general_info, attrs) do
    general_info
    |> cast(attrs, [
      :contact_id,
      :hospital,
      :website,
      :pet_insurance_supplier,
      :date_of_birth,
      :driver_license_number,
      :driver_license_issuer,
      :driver_license_expiry,
      :national_id_number,
      :passport_number,
      :credit_limit_name,
      :contact_details_confirmed,
      :consolidate_invoices
    ])
    |> validate_required([:contact_id])
    |> unique_constraint(:contact_id, name: :contact_general_info_contact_id_index)
  end
end
