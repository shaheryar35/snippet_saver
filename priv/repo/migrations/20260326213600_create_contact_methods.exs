defmodule SnippetSaver.Repo.Migrations.CreateContactMethods do
  use Ecto.Migration

  def change do
    create table(:contact_methods) do
      add :type, :string
      add :value, :string
      add :is_primary, :boolean, default: false, null: false
      add :allow_sms, :boolean, default: false, null: false
      add :allow_email, :boolean, default: false, null: false
      add :contact_id, references(:contacts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:contact_methods, [:contact_id])
  end
end
