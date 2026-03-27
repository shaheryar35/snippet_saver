defmodule SnippetSaver.Repo.Migrations.CreateContactRoleTypes do
  use Ecto.Migration

  def change do
    create table(:contact_role_types) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:contact_role_types, [:name])
  end
end
