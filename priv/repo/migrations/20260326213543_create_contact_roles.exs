defmodule SnippetSaver.Repo.Migrations.CreateContactRoles do
  use Ecto.Migration

  def change do
    create table(:contact_roles) do
      add :contact_id, references(:contacts, on_delete: :nothing)
      add :contact_role_type_id, references(:contact_role_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:contact_roles, [:contact_id, :contact_role_type_id],
             name: :contact_roles_contact_id_contact_role_type_id_index
           )

    create index(:contact_roles, [:contact_role_type_id])
  end
end
