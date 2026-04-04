defmodule SnippetSaver.Repo.Migrations.AddArchivedAndAuditToContactRoleTypes do
  use Ecto.Migration

  def up do
    drop_if_exists unique_index(:contact_role_types, [:name])

    alter table(:contact_role_types) do
      add :archived, :boolean, null: false, default: false
      add :inserted_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)
    end

    create unique_index(:contact_role_types, [:name],
             where: "archived = false",
             name: :contact_role_types_name_active_unique_index
           )
  end

  def down do
    drop_if_exists unique_index(:contact_role_types, [:name],
                     name: :contact_role_types_name_active_unique_index
                   )

    alter table(:contact_role_types) do
      remove :updated_by_id
      remove :inserted_by_id
      remove :archived
    end

    create unique_index(:contact_role_types, [:name])
  end
end
