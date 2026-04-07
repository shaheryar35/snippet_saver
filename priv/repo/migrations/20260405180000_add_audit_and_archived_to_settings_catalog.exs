defmodule SnippetSaver.Repo.Migrations.AddAuditAndArchivedToSettingsCatalog do
  use Ecto.Migration

  def change do
    for table <- [:species, :breeds, :colours, :master_problem_templates] do
      alter table(table) do
        add_if_not_exists :archived, :boolean, null: false, default: false
        add_if_not_exists :inserted_by_id, references(:users, on_delete: :nilify_all)
        add_if_not_exists :updated_by_id, references(:users, on_delete: :nilify_all)
      end
    end
  end
end
