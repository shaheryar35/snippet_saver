defmodule SnippetSaver.Repo.Migrations.CreateHearAboutOptions do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:hear_about_options) do
      add :name, :string
      add :is_active, :boolean, default: true, null: false
      add :category, :string
      add :archived, :boolean, default: false, null: false
      add :inserted_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end
  end
end
