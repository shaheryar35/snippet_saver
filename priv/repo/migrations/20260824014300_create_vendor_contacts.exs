defmodule SnippetSaver.Repo.Migrations.CreateVendorContacts do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:vendor_contacts) do
      add :name, :string
      add :role, :string
      add :vendor_id, references(:vendors, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:vendor_contacts, [:vendor_id])
  end
end
