defmodule SnippetSaver.Repo.Migrations.CreateSpecies do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:species) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
