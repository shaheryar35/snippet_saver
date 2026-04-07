defmodule SnippetSaver.Repo.Migrations.CreatePatientImages do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:patient_images) do
      add :image_url, :string
      add :file_name, :string
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:patient_images, [:patient_id])
  end
end
