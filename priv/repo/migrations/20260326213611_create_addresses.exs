defmodule SnippetSaver.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :type, :string
      add :street_address, :text
      add :suburb, :string
      add :postcode, :string
      add :city, :string
      add :country, :string
      add :longitude, :decimal
      add :latitude, :decimal
      add :address_name, :string
      add :contact_id, references(:contacts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:addresses, [:contact_id])
  end
end
