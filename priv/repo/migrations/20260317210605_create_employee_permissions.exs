# priv/repo/migrations/[timestamp]_create_employee_permissions.exs
defmodule SnippetSaver.Repo.Migrations.CreateEmployeePermissions do
  use Ecto.Migration

  def change do
    create table(:employee_permissions) do
      add :employee_id, references(:employees, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:employee_permissions, [:employee_id])
    create index(:employee_permissions, [:permission_id])

    create unique_index(:employee_permissions, [:employee_id, :permission_id],
             name: :employee_permissions_employee_id_permission_id_index
           )
  end
end
