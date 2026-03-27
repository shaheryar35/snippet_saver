defmodule SnippetSaver.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :business_code, :string
      add :is_individual, :boolean, default: true, null: false
      add :title, :string
      add :first_name, :string
      add :last_name, :string
      add :notes, :text
      add :notes_important, :boolean, default: false, null: false
      add :preferred_contact_method_id, :integer
      add :hear_about_option_id, :integer
      add :discount_group_id, :integer
      add :financial_group_id, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
