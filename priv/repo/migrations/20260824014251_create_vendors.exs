defmodule SnippetSaver.Repo.Migrations.CreateVendors do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:vendors) do
      add :company_name, :string
      add :archived, :boolean, default: false, null: false
      add :inserted_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end
  end
end
