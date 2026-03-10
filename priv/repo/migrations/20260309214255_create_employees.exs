defmodule SnippetSaver.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees) do
      add :name, :string
      add :email, :string
      add :company, :string
      add :department, :string
      add :role, :string
      add :active, :boolean, default: false, null: false
      add :salary, :decimal

      timestamps(type: :utc_datetime)
    end
  end
end
