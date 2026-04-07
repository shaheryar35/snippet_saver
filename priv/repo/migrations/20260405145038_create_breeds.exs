defmodule SnippetSaver.Repo.Migrations.CreateBreeds do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:breeds) do
      add :name, :string
      add :species_id, references(:species, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:breeds, [:species_id])
  end
end
