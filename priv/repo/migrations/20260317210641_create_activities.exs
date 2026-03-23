defmodule SnippetSaver.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :action, :string
      add :resource_type, :string
      add :resource_id, :integer
      add :details, :map
      add :ip_address, :string
      add :user_agent, :string
      add :employee_id, references(:employees, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:activities, [:employee_id])
  end
end
