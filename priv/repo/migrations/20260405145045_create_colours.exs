defmodule SnippetSaver.Repo.Migrations.CreateColours do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:colours) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
