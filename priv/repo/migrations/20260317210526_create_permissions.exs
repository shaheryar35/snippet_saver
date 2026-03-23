defmodule SnippetSaver.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string
      add :resource, :string
      add :action, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:name])
  end
end
